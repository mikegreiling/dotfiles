# Runbook — recording B-Stock feature demo videos with Playwright

Deep reference for the `bstock-demo-video` skill. The skill ships a working
template (`assets/demo-template/`); this explains *why* each piece exists and how
to adapt it to any frontend change. Born from the GLOB-4588 parcel demo, but the
machinery is feature-agnostic.

## 0. Prerequisites
- **VPN** — the dev backend (`*.bstock-dev.com`) is VPN-gated.
- **A running app at `baseUrl` that contains the feature.** Pre-merge: run the
  branch's dev server (e.g. home-portal `npm run dev` → :3030) and keep `baseUrl`
  on localhost. Post-merge: point `baseUrl` at the deployed env (no local server).
- **Node** ≥ 20 for the recorder; **ffmpeg** for trim/encode.
- The throwaway project lives at `<repo>/demo/` (git-excluded; never add
  `@playwright/test` to the portal's package.json/lockfile).

## 1. Auth — bypass the Cloudflare Turnstile (`global-setup.ts`)
Dev login federates to **FusionAuth** behind a **Cloudflare Turnstile** widget;
scripted *browser* login fails. Mint a session **server-side** instead (ported
from `fe-scripts/src/api/accounts.ts` `login()`, BUGS-5218):
1. `GET <authBase>/oauth2/authorize?...` with `redirect_uri=<baseUrl>/acct/login`,
   `response_type=code`, `scope=offline_access`, `client_id=<env>`. Capture
   `Set-Cookie` (`oauth_context`) + follow up to ~5 redirects to the login HTML.
2. Scrape **all hidden inputs** from the login `<form>` (incl. `captcha_token`,
   `tenantId`, `nonce`) + the form `action`.
3. `POST` (urlencoded) the captured cookies + `loginId`,`password`,
   `showPasswordField=true`,`rememberDevice=true`. The form POST is **not**
   Turnstile-gated server-side.
4. Follow redirects (carrying cookies) to the `<baseUrl>/acct/login?code=…`
   callback. **Don't fetch it from Node** (single-use code).
5. `page.goto(callbackUrl)` so the **portal** exchanges the code + sets its own
   `bstock_access_token`/`bstock_refresh_token`; then `context.storageState(...)`.
Re-running globalSetup mints fresh each run, unattended.

Per-env FA client ids + hosts: see `fusionauth-client-ids.md`. The login identity
(email + password) is resolved at runtime — env `BSTOCK_DEMO_EMAIL`/
`BSTOCK_DEMO_PASSWORD` or git-ignored `demo/creds.json` `{"email","password"}` —
and is intentionally NOT in `demo.config.ts`. The skill assumes no path; the agent
gets the pair from the user (a file they point to + which account, typed in, or
already-exported env). Some features need the account to have a saved destination
address (e.g. shipping quotes throw `destinationLocationId required`).

## 2. Force LaunchDarkly flags (`ld-intercept.ts` → `forceFlags`)
Most flags have **no in-app override**. Intercept the client SDK: rewrite
`**/sdk/evalx/**` to set each (kebab-case) flag `{value:true,variation:1,…}` and
`route.abort()` on `**clientstream.launchdarkly.com**` so the stream can't undo it.
Only flips the gate — real backend data still flows.

## 3. Find real test data (`discover.spec.ts`)
Prefer real data over mocking. Replay the app's own search with an added
**top-level** facet: `POST <search host>/v1/all-listings/listings` (buyer bearer
token captured from a live request) with e.g. `{transportMode:['PARCEL'],limit:50}`.
Nesting the facet under `filters`/`selectedFilters` is silently ignored. Keep
future-`endTime` results. Auctions expire → re-discover each session. Note:
`fe-scripts` can't create Parcel listings (LTL only); Shippo test rating is
non-deterministic. For non-listing subjects, write an analogous discovery or fill
the ID manually.

## 4. Navigate & interact — feature-specific, composed from the kit
There is **no fixed shape**. General recipe: navigate → **tour the relevant
region** → perform the change being demoed → `confirmOrClose`. Compose `human.ts`:
- `installCursor` / `recenterCursor` (centered start) / `moveTo` / `hoverClick` /
  `humanType`.
- `tour(page, {region})` — pans a scroll region top→bottom with pauses. `region`
  omitted = the **window**; `'modal'` = the confirm-modal scroller; any CSS string
  = that scroll container (side panel, table, drawer). Use whatever the feature
  needs.
- Modal conveniences: `scrollModal`, `closeModal`, `confirmOrClose({submit})`.
The parcel example (`demo.spec.ts`) shows the modal case; copy + adapt for yours.

## 5. Recording & styling standards
- **viewport == video.size** (one constant in `demo.config.ts size`, default
  1440×1024). Unequal → gray border. Never spread `devices['Desktop Chrome']`
  (forces 1280×720). No `slowMo` (robotic) — pace with `beat`s + eased cursor.
- `workers:1`, generous timeouts (VPN is slow). One `test()` per scenario → one
  `.webm`.
- **Hide dev overlays** (`overlays.ts` `hideChrome`): localStorage disable flags
  (`BSTOCK_DEV_TOOLS_ENABLED`, `BSTOCK_CONSENT_DEBUG_ENABLED`,
  `TanstackQueryDevtoolsPanel_open`) + CSS for `[data-testid="bstock-dev-tools"]`,
  `.tsqd-open-btn-container`, `[data-nextjs-toast]`, `#__next-build-watcher`, and
  the Next.js indicator host `nextjs-portal` (shadow DOM → hide the host). The blue
  support/chat bubble is real product chrome — leave it unless asked.
- Deliberate **pauses** (1.5–3s) at each meaningful state.

## 6. Post-processing (`encode.sh`)
Trim the SSR/hydration white lead-in (negate + `blackdetect` → input-seek), then
`libx264 -pix_fmt yuv420p -movflags +faststart`; concat per-scenario clips into
`combined.mp4`. Eyeball the first output frame (mostly-white pages can over-trim).

## 7. Package & hand off
- `encode.sh` → `videos/*.mp4`. `bundle.sh` → lean `…-bundle.zip` (excludes the
  **entire** node_modules + outputs + secrets) — the portable artifact others
  replay locally (`npm ci && npx playwright test`, given VPN + their own creds +
  the record IDs in the README).
- Hand the video(s) + bundle to the user (e.g. `SendUserFile`).

## 8. Guardrails
- **Stop before the real submit** unless a scenario sets `submit:true` on a
  disposable/seeded record. Selecting options / the user's own choices is fine.
- Don't mutate shared dev records others rely on.
- Don't commit `demo/` or `@playwright/test` into the target repo's tracked tree.
- See `pitfalls.md` for the first-try gotchas, and `setup-teardown.md` for the
  (future) resource-seeding extension point.
