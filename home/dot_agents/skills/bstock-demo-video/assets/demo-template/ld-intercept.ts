import type { BrowserContext, Page } from '@playwright/test'

/**
 * Force one or more LaunchDarkly flags ON at the network layer — no dashboard
 * access, no in-app override needed.
 *
 * The portals use `launchdarkly-react-client-sdk`, which on init fetches the full
 * flag set from `…/sdk/evalx/…` (GET, or POST in "report" mode) and then opens an
 * SSE stream on `clientstream.launchdarkly.com`. We rewrite the evalx response to
 * set each flag true, and abort the stream so it can't push a contradicting value.
 *
 * Flag keys in the evalx payload are the original kebab-case keys (the SDK
 * camel-cases them client-side), so pass kebab keys, e.g. ['enable-parcel-quotes'].
 */
export async function forceFlags(
  target: BrowserContext | Page,
  keys: string[]
) {
  if (!keys.length) return
  await target.route('**/sdk/evalx/**', async (route) => {
    let json: Record<string, unknown> = {}
    try {
      const response = await route.fetch()
      json = await response.json().catch(() => ({}))
    } catch {
      // If the real request fails, still inject minimal payloads below.
    }
    for (const key of keys) {
      const existing = (json[key] ?? {}) as Record<string, unknown>
      const version =
        typeof existing.version === 'number' ? existing.version + 1000 : 1000
      json[key] = {
        ...existing,
        value: true,
        variation: 1,
        version,
        trackEvents: false,
      }
    }
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(json),
    })
  })
  await target.route('**clientstream.launchdarkly.com**', (route) =>
    route.abort()
  )
}
