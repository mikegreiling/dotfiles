import { test, expect, type Page } from '@playwright/test'

import demo from './demo.config'
import { forceFlags } from './ld-intercept'
import { hideChrome } from './overlays'
import {
  installCursor,
  recenterCursor,
  hoverClick,
  humanType,
  scrollModal,
  smoothScrollIntoView,
  confirmOrClose,
} from './human'

// ─────────────────────────────────────────────────────────────────────────────
// WORKED EXAMPLE — the parcel bid flow (GLOB-4588). This is a PATTERN to copy and
// adapt, NOT a fixed shape. For a different feature, rewrite the test bodies using
// the same kit: navigate → tour the relevant region → perform the change →
// confirmOrClose. Keep non-deterministic IDs in demo.config `records`.
// ─────────────────────────────────────────────────────────────────────────────

const R = demo.records
const beat = (page: Page, ms = 1500) => page.waitForTimeout(ms)
const scn = (name: string) => demo.scenarios.find((s) => s.name === name)

test.beforeEach(async ({ context, page }) => {
  await forceFlags(context, demo.forceFlags)
  await installCursor(page)
  await hideChrome(context)
})

/** Open the Place Bid confirmation modal like a user would. */
async function openBidModal(page: Page, listingId: string) {
  await page.goto(`/buy/listings/details/${listingId}`, {
    waitUntil: 'domcontentloaded',
  })
  await page.waitForLoadState('networkidle').catch(() => {})
  await recenterCursor(page)
  await beat(page, 1000)
  await humanType(page, page.locator('input[name="amount"]').first(), '500')
  await beat(page, 600)
  await hoverClick(page, page.getByRole('button', { name: /^place bid$/i }).first())
}

test('01-view-and-select-parcel-rates', async ({ page }) => {
  test.setTimeout(200_000)
  await openBidModal(page, R.rates)

  const rateList = page.locator('[data-testid="parcel-rate-list"]')
  await rateList.waitFor({ state: 'visible', timeout: 40_000 })
  const cards = page.locator('[data-testid="parcel-rate-card"]')
  const count = await cards.count()
  expect(count).toBeGreaterThan(1)
  expect(await page.getByText(/cheapest/i).count()).toBeGreaterThan(0)

  // Tour the modal top → bottom (address, payment, all rates, total).
  await beat(page, 600)
  await scrollModal(page, 'top', 700)
  await beat(page, 2200)
  await scrollModal(page, 'bottom', 2400)
  await beat(page, 2400)

  // Select a different (non-preselected) rate; show the total update.
  let selectedIdx = 0
  for (let i = 0; i < count; i++) {
    if (await cards.nth(i).locator('input[type="radio"]:checked').count()) {
      selectedIdx = i
      break
    }
  }
  const targetIdx = selectedIdx === count - 1 ? 0 : count - 1
  await hoverClick(page, cards.nth(targetIdx))
  await beat(page, 3000)
  await expect(cards.nth(targetIdx).locator('input[type="radio"]')).toBeChecked()
  await beat(page, 2000)

  await confirmOrClose(page, {
    submit: scn('01-view-and-select-parcel-rates')?.submit,
    confirmName: /confirm (max )?bid/i,
  })
})

test('02-no-rates-blocks-payment', async ({ page }) => {
  test.setTimeout(200_000)
  await openBidModal(page, R.noRates)

  const banner = page.locator('[data-testid="parcel-no-rates-banner"]')
  await banner.waitFor({ state: 'visible', timeout: 40_000 })
  await expect(banner).toHaveAttribute('role', 'alert')

  await beat(page, 600)
  await scrollModal(page, 'top', 700)
  await beat(page, 2400)
  await scrollModal(page, 'bottom', 2000)
  await beat(page, 2000)

  const confirm = page.getByRole('button', { name: /confirm (max )?bid/i }).first()
  await smoothScrollIntoView(page, confirm)
  await expect(confirm).toBeDisabled()
  await beat(page, 2500)

  // No-rates blocks payment, so this scenario always closes (never submits).
  await confirmOrClose(page, { submit: false })
})
