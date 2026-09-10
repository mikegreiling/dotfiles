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

Three things the mint depends on, each of which broke it once — see pitfalls
21–23 for the full symptoms:
- **`channel: 'chrome'`.** The mint launches its own browser; the bundled
  Chromium cannot reach the VPN-routed dev network at all on a B-Stock
  workstation, so the code exchange hangs and no cookie is ever set.
- **PKCE.** accounts-portal mints a pair on sign-in, keeps it in
  `sessionStorage.oauth_challenge`, and verifies the echoed `state.csrf`. The
  mint therefore generates the pair itself, puts `code_challenge`/`S256` on the
  authorize request and `csrf` inside `state`, and seeds `sessionStorage` (via a
  stubbed blank page on the origin) before loading the callback.
- **Unescaping the scraped hidden inputs.** They arrive HTML-escaped; the
  escaped `state` would otherwise overwrite the real one and lose the csrf.

The exchange the callback page performs is one request —
`GET {SERVICE_HOST_ACCOUNTS}/v1/people/login?code=<code>&redirectUri=<mintUrl>/acct/login&codeVerifier=<verifier>`
— and its response is what becomes `bstock_access_token`/`bstock_refresh_token`.
Since the mint now owns the verifier, that call can be replayed from Node and the
tokens planted with `context.addCookies` instead of loading the callback. The
browser path stays the default (it is what the portal actually does, so it
survives portal changes); the server-side variant is the fallback if the callback
page ever becomes undriveable.

**`redirect_uri` must be registered, and on dev only `:3030` is.** The FA client
accepts `http://localhost:3030/acct/login` and the deployed hosts; any other
localhost port answers `invalid_redirect_uri`. If 3030 is busy, leave `baseUrl` on
whatever port the app is on and set `demo.config.mintUrl` to
`https://bstock-dev.com` — the mint runs against that origin and copies the
`bstock_*` cookies onto `baseUrl`'s hostname (cookies are not port-scoped). See
pitfall 31.

Per-env FA client ids + hosts: see `fusionauth-client-ids.md`. The login identity
(email + password) is resolved at runtime — env `BSTOCK_DEMO_EMAIL`/
`BSTOCK_DEMO_PASSWORD` or git-ignored `demo/creds.json` `{"email","password"}` —
and is intentionally NOT in `demo.config.ts`. The skill assumes no path; the agent
gets the pair from the user (a file they point to + which account, typed in, or
already-exported env). Some features need the account to have a saved destination
address (e.g. shipping quotes throw `destinationLocationId required`).

## 2. Force LaunchDarkly flags
Three mechanisms, and **which one you need depends on where the flag is read**:

- **Client reads** (`useFlag` in a `'use client'` component) — `forceFlags`
  (`ld-intercept.ts`) rewrites `**/sdk/evalx/**` to set each kebab-case flag
  `{value:true,variation:1,…}` and `route.abort()`s
  `**clientstream.launchdarkly.com**` so the stream can't undo it.
- **Server reads** (`getRequestLocals().evaluateFlag` in an App Router
  page/layout/server component) — evalx interception **cannot reach these**;
  they are evaluated by the node server SDK inside the dev server. Use fe-core's
  URL flag override instead, which is honoured on both sides in non-prod: put
  `?<flag-key>=true` on the URL for client reads, and send
  `x-search-params: <flag-key>=true` as a request header for server reads
  (`context.setExtraHTTPHeaders`). The header is normally set by
  `contentSecurityPolicyMiddleware`, but home-portal's `src/proxy.ts`
  short-circuits `/buy/*` before it in dev — see pitfall 24.
- **SSR-bootstrapped SDKs** (cs-portal: `LDProvider … options.bootstrap` fed
  from `pageProps.featureFlags`) — the client SDK never issues an evalx request
  at all, so `forceFlags` is a silent no-op. Rewrite the SSR document instead:
  `context.route` the document request and splice the key into the
  `featureFlags":{` object in `__NEXT_DATA__`, dropping `content-length`. Recipe
  in pitfall 30.

None of them touches LaunchDarkly, and all only flip the gate — real backend data
still flows. A flag that does not exist in LD yet overrides fine.

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
  `clickInPlace` / `humanType`. `hoverClick` scrolls its target to centre first —
  use `clickInPlace` for anything anchored and already on screen (dropdown/menu
  items, popovers), or the click lands behind the moving menu (pitfall 33).
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
Trim the dead lead-in — WHITE (SSR/hydration) *or* BLACK (real Chrome's recorder
emits pre-paint black frames), measured both ways with `blackdetect` and seeking
past whichever runs longer — then `libx264 -pix_fmt yuv420p -movflags +faststart`;
concat per-scenario clips into `combined.mp4`. Every ffmpeg call runs with
`-nostdin` so it can't swallow the clip loop's stdin (pitfall 29). Eyeball the
first output frame (`ffmpeg -ss 0 -i out.mp4 -frames:v 1 f0.png`) — mostly-white
pages can over-trim.

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
- `demo/` is git-excluded but **not** necessarily tsconfig-excluded: a repo whose
  `include` is `**/*.ts` (home-portal) type-checks the scaffold too. Move it aside
  before trusting `npm run type-check` output (pitfall 34).
- See `pitfalls.md` for the first-try gotchas, and `setup-teardown.md` for the
  (future) resource-seeding extension point.
