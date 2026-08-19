import { test } from '@playwright/test'

import demo from './demo.config'

/**
 * Refresh stale subject IDs. Auction listings expire, so the IDs in
 * demo.config.records go stale — this finds CURRENT, ACTIVE candidates by
 * replaying the portal's own search request with an added top-level facet filter,
 * and logs active IDs (future endTime) to paste back into demo.config.
 *
 * Listings/search-portal specific. For other portals/records, write an analogous
 * discovery (or fill the param manually). Tune FACET for your subject.
 */
const FACET: Record<string, unknown> = { transportMode: ['PARCEL'] }

test('discover active candidates', async ({ page }) => {
  test.setTimeout(150_000)

  let captured: { url: string; headers: Record<string, string>; body: string } | null =
    null
  page.on('request', (req) => {
    if (
      req.url().includes('/all-listings/listings') &&
      req.method() === 'POST' &&
      !captured
    ) {
      captured = {
        url: req.url(),
        headers: req.headers(),
        body: req.postData() ?? '',
      }
    }
  })

  await page.goto('/all-auctions', { waitUntil: 'domcontentloaded' })
  await page.waitForTimeout(8000)
  if (!captured) {
    // eslint-disable-next-line no-console
    console.log('[discover] never captured a search request — adjust the URL match')
    return
  }

  let body: Record<string, unknown> = {}
  try {
    body = JSON.parse(captured.body)
  } catch {
    /* ignore */
  }
  // The facet must be TOP-LEVEL in the body — nesting under filters is ignored.
  const res = await page.request.post(captured.url, {
    headers: {
      authorization: captured.headers['authorization'] ?? '',
      'content-type': 'application/json',
    },
    data: { ...body, ...FACET, limit: 50 },
  })
  const json = await res.json().catch(() => ({}) as any)
  const listings: any[] = json.listings ?? json.results ?? []
  const now = Date.now()
  const active = listings
    .map((l) => ({
      id: l.listingId ?? l.id,
      end: l.endTime ?? l.buyNowEndTime,
      pricingStrategy: l.pricingStrategy,
      buyNow: l.buyNow,
    }))
    .filter((l) => l.end && new Date(l.end).getTime() > now)
  // eslint-disable-next-line no-console
  console.log(
    `[discover] env=${demo.env} status=${res.status()} total=${listings.length} active=${active.length}`,
    JSON.stringify(active.slice(0, 15), null, 2)
  )
})
