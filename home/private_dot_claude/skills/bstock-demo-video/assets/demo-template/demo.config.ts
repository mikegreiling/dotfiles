/**
 * THE PARAMETER FILE — fill this per task. Everything else in the project is
 * deterministic, reusable machinery. Non-deterministic, feature-specific inputs
 * (which env, which records/IDs, which flags, which scenarios) live HERE so the
 * Playwright script stays replayable: swap these values, re-run, get the video.
 *
 * The LOGIN IDENTITY (email + password) is deliberately NOT here — it is a
 * credential resolved at runtime (env BSTOCK_DEMO_EMAIL/BSTOCK_DEMO_PASSWORD or a
 * git-ignored demo/creds.json). The skill is agnostic about which account is used
 * and where it lives; the agent supplies it from whatever the user provides.
 */

export type Scenario = {
  /** Used to name the output video; keep it filesystem-safe + ordered (01-, 02-). */
  name: string
  /** Path to navigate to; ${key} is substituted from `records`. */
  goto: string
  /** Perform the real mutating action at the end? Only on seeded/disposable records. */
  submit?: boolean
}

export type DemoConfig = {
  env: 'dev' | 'qa' | 'staging' | 'localhost'
  baseUrl: string
  /** Where to land after login (any authenticated path is fine). */
  afterLogin?: string
  /** LaunchDarkly flag keys to force ON (kebab-case), or [] for none. */
  forceFlags: string[]
  /** Recording size — viewport AND video are locked to this (avoids gray borders). */
  size: { width: number; height: number }
  /** Subject record IDs (listings, orders, disputes, …) referenced by scenarios. */
  records: Record<string, string>
  scenarios: Scenario[]
}

// ───────────────────────── EXAMPLE: parcel bid-flow (GLOB-4588) ─────────────────────────
// Replace records + scenarios for your feature. IDs go stale (auctions expire) —
// refresh with `npx playwright test discover.spec.ts` (see references/runbook.md).
const config: DemoConfig = {
  env: 'dev',
  baseUrl: 'http://localhost:3030',
  afterLogin: '/buy/user/bids',
  // Login identity comes from env/creds.json (see README). The parcel example
  // needs a BUYER account with visibility to the listings below + a saved
  // destination address.
  forceFlags: ['enable-parcel-quotes'],
  size: { width: 1440, height: 1024 },
  records: {
    rates: '6a320b97faee575b4494a052', // active Parcel auction w/ live Shippo rates
    noRates: '67f6b43d6261d0ed933fdd0a', // Canada-origin → NO_RATES_FOUND
  },
  scenarios: [
    { name: '01-view-and-select-parcel-rates', goto: '/buy/listings/details/${rates}', submit: false },
    { name: '02-no-rates-blocks-payment', goto: '/buy/listings/details/${noRates}', submit: false },
  ],
}

export default config
