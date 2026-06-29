import { existsSync, readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

import { chromium, type FullConfig } from '@playwright/test'

import config from './demo.config'

const here = dirname(fileURLToPath(import.meta.url))
const STORAGE = resolve(here, '.auth/buyer.json')

// Per-environment FusionAuth — see references/fusionauth-client-ids.md.
// dev is battle-tested; verify auth host for qa/staging before relying on them.
const FA: Record<string, { authBase: string; clientId: string }> = {
  dev: {
    authBase: 'https://auth-integ.bstock.com',
    clientId: 'd05d5cfb-7a1f-49c7-8edd-e27104c3c2f8',
  },
  qa: {
    authBase: 'https://auth-integ.bstock.com',
    clientId: 'ac89ac23-e588-4743-a6f0-7cc78b871262',
  },
  staging: {
    authBase: 'https://auth.bstock-staging.com',
    clientId: '7e3f9663-1e37-4472-b25e-d6234cc91207',
  },
  localhost: {
    authBase: 'http://localhost:9011',
    clientId: '003cac24-2e16-4d3b-bbaf-a85aeff14d16',
  },
}

function resolvePassword(): string {
  if (process.env.BSTOCK_DEMO_PASSWORD) return process.env.BSTOCK_DEMO_PASSWORD
  const credsPath = resolve(here, 'creds.json')
  if (existsSync(credsPath)) {
    const c = JSON.parse(readFileSync(credsPath, 'utf8'))
    if (c?.buyer?.password) return c.buyer.password as string
  }
  throw new Error(
    '[global-setup] no password — set BSTOCK_DEMO_PASSWORD or create demo/creds.json {"buyer":{"password":"…"}} (see README).'
  )
}

/**
 * Mint a fresh session WITHOUT the browser Turnstile widget by replaying
 * FusionAuth's hosted-login form POST server-side (ported from fe-scripts,
 * BUGS-5218), targeting redirect_uri=<baseUrl>/acct/login so the auth code is
 * valid for the target server. Hand the code to the portal in a browser so it
 * sets its own cookies, and persist storageState for the demo.
 */
export default async function globalSetup(_config: FullConfig) {
  const baseUrl = config.baseUrl
  const env = config.env ?? 'dev'
  const fa = FA[env]
  if (!fa) throw new Error(`[global-setup] unknown env "${env}"`)
  const email = config.buyer.email
  const password = resolvePassword()

  const authParams: Record<string, string> = {
    client_id: fa.clientId,
    'metaData.device.type': 'BROWSER',
    redirect_uri: `${baseUrl}/acct/login`,
    response_type: 'code',
    scope: 'offline_access',
    state: JSON.stringify({
      isEnterpriseUser: true,
      identityProviderType: 'FUSIONAUTH',
      redirectAfterLogin: config.afterLogin ?? '/',
    }),
    timezone: 'America/Chicago',
  }

  const jar = new Map<string, string>()
  const addCookies = (res: Response) => {
    for (const c of res.headers.getSetCookie?.() ?? []) {
      const [pair] = c.split(';')
      const idx = pair.indexOf('=')
      if (idx > 0) jar.set(pair.slice(0, idx).trim(), pair.slice(idx + 1).trim())
    }
  }
  const cookieHeader = () =>
    [...jar.entries()].map(([k, v]) => `${k}=${v}`).join('; ')
  const get = (url: string) =>
    fetch(url, {
      method: 'GET',
      redirect: 'manual',
      headers: { Cookie: cookieHeader(), 'User-Agent': 'Mozilla/5.0' },
    })

  // 1) GET authorize → oauth_context cookie + login-page HTML.
  let url = `${fa.authBase}/oauth2/authorize?${new URLSearchParams(authParams)}`
  let res = await get(url)
  addCookies(res)
  for (let i = 0; i < 5 && res.status >= 300 && res.status < 400; i++) {
    const loc = res.headers.get('location')
    if (!loc) break
    url = new URL(loc, url).toString()
    res = await get(url)
    addCookies(res)
  }
  const html = await res.text()

  const hidden: Record<string, string> = {}
  for (const m of html.matchAll(/<input\b[^>]*>/gi)) {
    const tag = m[0]
    if (!/type=["']hidden["']/i.test(tag)) continue
    const name = tag.match(/name=["']([^"']+)["']/i)?.[1]
    const val = tag.match(/value=["']([^"']*)["']/i)?.[1] ?? ''
    if (name) hidden[name] = val
  }
  const actionM = html.match(/<form\b[^>]*\baction=["']([^"']+)["']/i)
  const postUrl = actionM
    ? new URL(actionM[1].replace(/&amp;/g, '&'), `${fa.authBase}/oauth2/`).toString()
    : `${fa.authBase}/oauth2/authorize`

  // 2) POST credentials.
  const body = new URLSearchParams({
    ...authParams,
    ...hidden,
    showPasswordField: 'true',
    loginId: email,
    password,
    rememberDevice: 'true',
    __cb_rememberDevice: 'false',
  }).toString()
  res = await fetch(postUrl, {
    method: 'POST',
    redirect: 'manual',
    headers: {
      Cookie: cookieHeader(),
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'Mozilla/5.0',
    },
    body,
  })
  addCookies(res)
  if (!res.headers.has('location')) {
    throw new Error(
      `[global-setup] no redirect after login POST (status ${res.status}) — credentials rejected or captcha enforced.`
    )
  }

  // 3) Follow redirects to the <baseUrl> ?code= callback.
  let loc: string | null = res.headers.get('location')
  let callbackUrl: string | null = null
  for (let i = 0; i < 8 && loc; i++) {
    const abs = new URL(loc, postUrl)
    if (abs.host === new URL(baseUrl).host && abs.searchParams.has('code')) {
      callbackUrl = abs.toString()
      break
    }
    res = await get(abs.toString())
    addCookies(res)
    loc = res.headers.get('location')
  }
  if (!callbackUrl)
    throw new Error('[global-setup] did not reach the ?code= callback.')

  // 4) Hand the code to the portal in a browser so it sets its own cookies.
  const browser = await chromium.launch()
  try {
    const context = await browser.newContext()
    const page = await context.newPage()
    await page.goto(callbackUrl, { waitUntil: 'domcontentloaded' })
    const deadline = Date.now() + 60_000
    while (Date.now() < deadline) {
      const u = new URL(page.url())
      if (u.host === new URL(baseUrl).host && !u.pathname.startsWith('/acct')) break
      await page.waitForTimeout(1_000)
    }
    await page.waitForTimeout(2_000)
    const cookieNames = (await context.cookies()).map((c) => c.name)
    if (!cookieNames.includes('bstock_access_token')) {
      throw new Error(
        `[global-setup] bstock_access_token not set after callback (cookies: ${cookieNames.join(', ')})`
      )
    }
    await context.storageState({ path: STORAGE })
    // eslint-disable-next-line no-console
    console.log('[global-setup] session minted; storageState saved.')
  } finally {
    await browser.close()
  }
}
