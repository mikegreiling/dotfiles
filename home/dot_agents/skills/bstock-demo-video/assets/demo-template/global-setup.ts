import { createHash, randomBytes } from 'node:crypto'
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

/**
 * Resolve the login identity. The skill is AGNOSTIC about where credentials live
 * and which account is used — any of these works (first match wins):
 *   1. env vars  BSTOCK_DEMO_EMAIL + BSTOCK_DEMO_PASSWORD
 *   2. a git-ignored demo/creds.json  { "email": "…", "password": "…" }
 *      (also accepts the nested form { "buyer": { "email": "…", "password": "…" } })
 * The agent populates one of these from whatever the user provides (a creds file
 * they point to, a typed-in pair, an already-exported env var). No path is assumed.
 */
function resolveCreds(): { email: string; password: string } {
  const fromFile = (() => {
    const p = resolve(here, 'creds.json')
    if (!existsSync(p)) return {}
    const c = JSON.parse(readFileSync(p, 'utf8'))
    return { email: c.email ?? c.buyer?.email, password: c.password ?? c.buyer?.password }
  })()
  const email = process.env.BSTOCK_DEMO_EMAIL || fromFile.email
  const password = process.env.BSTOCK_DEMO_PASSWORD || fromFile.password
  if (!email || !password) {
    throw new Error(
      '[global-setup] missing login credentials. Provide an email + password via ' +
        'env (BSTOCK_DEMO_EMAIL / BSTOCK_DEMO_PASSWORD) or demo/creds.json ' +
        '{"email":"…","password":"…"}. The skill does not assume where creds live.'
    )
  }
  return { email, password }
}

/**
 * Mint a fresh session WITHOUT the browser Turnstile widget by replaying
 * FusionAuth's hosted-login form POST server-side (ported from fe-scripts,
 * BUGS-5218), targeting redirect_uri=<mintUrl>/acct/login so the auth code is
 * valid for the target server. Hand the code to the portal in a browser so it
 * sets its own cookies, and persist storageState for the demo.
 */
export default async function globalSetup(_config: FullConfig) {
  const baseUrl = config.baseUrl
  /**
   * Origin the OAuth dance runs against, when it cannot be `baseUrl`.
   *
   * The dev FusionAuth client's ONLY registered localhost redirect_uri is
   * `http://localhost:3030/acct/login` — verified 2026-09-10: a mint against
   * `http://localhost:3031/acct/login` comes back `invalid_redirect_uri` while
   * 3030 serves the login form. When 3030 is busy, run the app on another port,
   * set `mintUrl` to the always-registered deployed dev host, and the
   * `bstock_*` cookies are transplanted onto the local origin at the end.
   * Cookies are not port-scoped, and the local portal only cares that a valid
   * `bstock_access_token` arrives on the request.
   *
   * Everything below that used to key on `baseUrl` keys on this instead: the
   * redirect_uri, the callback host match, and the origin the PKCE pair is
   * seeded on (sessionStorage is per-origin, and the callback page that reads
   * it is served by whichever host owns `/acct/login`).
   */
  const mintUrl = config.mintUrl ?? baseUrl
  const env = config.env ?? 'dev'
  const fa = FA[env]
  if (!fa) throw new Error(`[global-setup] unknown env "${env}"`)
  const { email, password } = resolveCreds()

  // ── PKCE (RFC 7636) + anti-CSRF nonce ──────────────────────────────────────
  // accounts-portal's OAuth2RedirectPage now mints a PKCE pair on sign-in,
  // stashes it in sessionStorage under `oauth_challenge`, and on the callback
  // (a) requires the echoed `state.csrf` to match and (b) sends the stored
  // `codeVerifier` on the token exchange. A code minted out-of-band has no pair
  // in the tab, so the page logs `login reauthorize {reason: lost-pair}` and
  // restarts authorization — straight into the Turnstile we are avoiding.
  // So: mint the pair HERE, bind the code to it, and seed sessionStorage with
  // the same pair before handing the browser the callback URL.
  // Shapes must match accounts-portal `src/app/helpers/auth/oauthChallenge.ts`.
  const b64url = (b: Buffer) => b.toString('base64url')
  const codeVerifier = b64url(randomBytes(32))
  const codeChallenge = b64url(createHash('sha256').update(codeVerifier).digest())
  const csrf = b64url(randomBytes(32))

  const state = JSON.stringify({
    isEnterpriseUser: true,
    identityProviderType: 'FUSIONAUTH',
    redirectAfterLogin: config.afterLogin ?? '/',
    csrf,
  })

  const authParams: Record<string, string> = {
    client_id: fa.clientId,
    'metaData.device.type': 'BROWSER',
    redirect_uri: `${mintUrl}/acct/login`,
    response_type: 'code',
    scope: 'offline_access',
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
    state,
    timezone: 'America/Chicago',
  }

  const jar = new Map<string, string>()
  const addCookies = (res: Response) => {
    for (const c of res.headers.getSetCookie?.() ?? []) {
      const pair = c.split(';')[0] ?? ''
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

  // Hidden-input values come out of the HTML still entity-escaped. `state` is
  // JSON, so its quotes arrive as `&quot;` — and because `hidden` is spread
  // AFTER `authParams` below, that escaped copy would replace our clean state
  // and travel all the way back to the callback, where accounts-portal's
  // `parseStateObject` does a bare `JSON.parse` and returns null (no csrf → a
  // csrf-mismatch reauthorize). Unescape everything, then re-assert `state`.
  const unescapeHtml = (s: string) =>
    s
      .replace(/&quot;/g, '"')
      .replace(/&#39;|&apos;/g, "'")
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&')

  const hidden: Record<string, string> = {}
  for (const m of html.matchAll(/<input\b[^>]*>/gi)) {
    const tag = m[0]
    if (!/type=["']hidden["']/i.test(tag)) continue
    const name = tag.match(/name=["']([^"']+)["']/i)?.[1]
    const val = tag.match(/value=["']([^"']*)["']/i)?.[1] ?? ''
    if (name) hidden[name] = unescapeHtml(val)
  }
  // Never let the scraped copies override what we deliberately bound the code to.
  hidden.state = state
  hidden.code_challenge = codeChallenge
  hidden.code_challenge_method = 'S256'
  const action = html.match(/<form\b[^>]*\baction=["']([^"']+)["']/i)?.[1]
  const postUrl = action
    ? new URL(action.replace(/&amp;/g, '&'), `${fa.authBase}/oauth2/`).toString()
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
    if (abs.host === new URL(mintUrl).host && abs.searchParams.has('code')) {
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
  // Same LNA opt-out as playwright.config `launchOptions` (pitfalls.md #13):
  // accounts-portal's OAuth2RedirectPage exchanges the ?code= client-side, and
  // that XHR from http://localhost:3030 to the VPN-routed dev account service
  // is blocked by Chromium's Local Network Access checks — the callback then
  // renders but never sets bstock_access_token.
  //
  // The exchange the callback performs is a single request —
  //   GET {SERVICE_HOST_ACCOUNTS}/v1/people/login
  //       ?code=<auth code>&redirectUri=<mintUrl>/acct/login&codeVerifier=<verifier>
  // — which answers with the access/refresh tokens the portal then writes to
  // `bstock_access_token` / `bstock_refresh_token`. Because we now own the PKCE
  // verifier, that call can also be replayed from Node and the tokens planted
  // with `context.addCookies` (same shape as the transplant below), skipping
  // the browser round-trip entirely. Keep the browser path as the default: it
  // matches what the portal really does, so it keeps working when the portal
  // changes what it stores.
  // `channel: 'chrome'` is REQUIRED here, not a preference — the bundled
  // Chromium is refused by the workstation's network agent and cannot reach the
  // VPN-routed dev services at all, so the callback's token exchange would hang.
  const browser = await chromium.launch({
    channel: 'chrome',
    args: ['--disable-features=LocalNetworkAccessChecks'],
  })
  try {
    const context = await browser.newContext()
    const page = await context.newPage()
    if (process.env.DEMO_AUTH_DEBUG) {
      page.on('console', (m) =>
        // eslint-disable-next-line no-console
        console.log('[cb console]', m.type(), m.text().slice(0, 300))
      )
      page.on('requestfailed', (r) =>
        // eslint-disable-next-line no-console
        console.log('[cb reqfail]', r.url().slice(0, 160), r.failure()?.errorText)
      )
      page.on('response', (r) => {
        if (r.status() >= 400)
          // eslint-disable-next-line no-console
          console.log('[cb resp]', r.status(), r.url().slice(0, 160))
      })
    }
    // Seed the PKCE pair into sessionStorage for this origin BEFORE the
    // callback runs. sessionStorage is per-tab and per-origin, so we need a
    // real document on <baseUrl> first — a stubbed blank page, because loading
    // any accounts-portal route would mint and store a pair of its own and
    // clobber ours.
    const BLANK = '**/__demo_pkce_seed'
    await page.route(BLANK, (route) =>
      route.fulfill({ status: 200, contentType: 'text/html', body: '<html></html>' })
    )
    await page.goto(`${mintUrl}/__demo_pkce_seed`, { waitUntil: 'domcontentloaded' })
    await page.evaluate(
      ({ key, value }) => sessionStorage.setItem(key, value),
      {
        key: 'oauth_challenge',
        value: JSON.stringify({ csrf, codeVerifier, codeChallenge }),
      }
    )
    await page.unroute(BLANK)

    await page.goto(callbackUrl, { waitUntil: 'domcontentloaded' })
    const deadline = Date.now() + 60_000
    while (Date.now() < deadline) {
      const u = new URL(page.url())
      if (u.host === new URL(mintUrl).host && !u.pathname.startsWith('/acct')) break
      await page.waitForTimeout(1_000)
    }
    await page.waitForTimeout(2_000)
    const cookieNames = (await context.cookies()).map((c) => c.name)
    if (process.env.DEMO_AUTH_DEBUG) {
      // eslint-disable-next-line no-console
      console.log('[cb] final url =', page.url())
      // eslint-disable-next-line no-console
      console.log(
        '[cb] body text =',
        (await page.locator('body').innerText().catch(() => '')).slice(0, 500)
      )
    }
    if (!cookieNames.includes('bstock_access_token')) {
      throw new Error(
        `[global-setup] bstock_access_token not set after callback (cookies: ${cookieNames.join(', ')})`
      )
    }
    // Transplant the session onto the origin the demo actually drives (see the
    // mintUrl note above). Cookies ignore ports, so a token minted for the
    // deployed dev host is accepted verbatim by the local server.
    if (new URL(mintUrl).host !== new URL(baseUrl).host) {
      const local = new URL(baseUrl)
      const minted = (await context.cookies()).filter((c) =>
        c.name.startsWith('bstock_')
      )
      await context.addCookies(
        minted.map((c) => ({
          name: c.name,
          value: c.value,
          domain: local.hostname,
          path: '/',
          httpOnly: c.httpOnly,
          secure: local.protocol === 'https:',
          sameSite: 'Lax' as const,
        }))
      )
      // eslint-disable-next-line no-console
      console.log(
        `[global-setup] copied ${minted.map((c) => c.name).join(', ')} onto ${local.hostname}`
      )
    }

    await context.storageState({ path: STORAGE })
    // eslint-disable-next-line no-console
    console.log('[global-setup] session minted; storageState saved.')
  } finally {
    await browser.close()
  }
}
