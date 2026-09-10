# Pitfalls — the first-try gotchas (the reason this skill exists)

Each of these cost a debugging round to discover. Honor them and the first run
usually just works.

1. **`role="dialog"` collision (highest-value).** The live-chat widget
   (`.livesdk__chat-sdk-window__container`) ALSO has `role="dialog"`. A bare
   `[role="dialog"]` grabs it instead of the real modal → the "scroll tour" does
   nothing for ~5s (reads as a dead pause) and strict-mode `waitFor` throws
   "resolved to N elements". **Always scope to `#modal-portal-wrapper`** (fe-core
   Modal's portal). `human.ts` `MODAL` already does this; `setModalSelector()` to
   override for other apps.

2. **Gray border around the video.** `viewport` must EQUAL `video.size`. The cause
   last time was spreading `devices['Desktop Chrome']` (forces 1280×720) into a
   1440×900 canvas. Use one `size` constant for both; no device preset.

3. **Turnstile blocks scripted login.** Don't drive the FusionAuth login form in a
   browser — mint server-side (global-setup). Bundled Chromium is flagged; even
   real Chrome is flaky and may be mid-update.

4. **No in-app LD flag toggle — but fe-core does have a URL override.** There is
   no localStorage switch and no dev UI for flipping arbitrary flags. Reach for,
   in order: `forceFlags` (evalx interception + clientstream abort) for *client*
   reads; fe-core's non-prod URL override for *server* reads (`?<flag-key>=true`
   plus the `x-search-params` header — #24); an SSR-payload rewrite for portals
   that bootstrap LD server-side (#30). Pick by **where the flag is read**.

5. **Subject IDs go stale.** Auctions expire; Shippo rating is non-deterministic
   and caches zero-quotes. Re-run `discover.spec.ts` and refresh `demo.config`.

6. **Dev overlays in frame.** Hide via `hideChrome` (localStorage flags + CSS). The
   Next.js dev indicator is in a `nextjs-portal` shadow DOM — hide the **host**
   element, not inner nodes (page CSS can't pierce the shadow root).

7. **blackdetect over-trim.** Mostly-white pages can extend the detected white
   interval into the loaded-but-white page; in practice it lands at first real
   paint, but eyeball the first output frame.

8. **VPN slowness.** `networkidle` + navigation can take many seconds; keep
   generous timeouts (`navigationTimeout ~90s`, per-test ~200s).

9. **Modal close is a no-op while pending.** Only `closeModal` after content has
   loaded; otherwise the click is swallowed.

10. **Never auto-submit.** Stop before the real Confirm unless `submit:true` on a
    disposable record — placing a real bid / completing an order mutates shared dev.

11. **cs-portal `/demo/*` pages 302 away under `npm run dev`.** cs-portal's
    `server.js` gates demo pages with `allowDemoPages = !(dev || ['dev','qa']
    .includes(PUBLIC_APP_ENV))`, so in a local dev server every `/csportal/demo/*`
    request redirects to the base path (you'll see the default Accounts page, not
    your demo). The fixture-fed `DemoPage` approach for component-isolation capture
    therefore needs a temporary local edit to that block (`const allowDemoPages =
    true`) + a server restart — revert before commit (`server.js` is tracked).
    Other portals may differ; check their custom server before assuming `/demo`
    is reachable in dev.

12. **No real parcel *order* on dev (FP-1947).** Parcel quote/markup data only
    exists on a real parcel order, of which there are effectively none on dev
    (scanned 1,800 recent buyer orders → 0 PARCEL; the 66 parcel *shipment*
    fixtures 404 in the order service). For a component-isolation capture, feed the
    card parcel-coerced fixture data via a throwaway `DemoPage` rather than hunting
    for a live order. To find/confirm orders by transport mode: order `findAll` has
    NO transportMode filter, so resolve each order's `shipping.quoteId` against the
    shipment service `GET /v1/quotes?_id=<csv>` (param is `_id`, not `id`) and read
    `quote.transportMode`; or list parcel shipments via `GET /v1/shipments?mode=PARCEL`.

13. **Chromium Local Network Access blocks localhost→VPN XHR.** Client-side
    XHR from `http://localhost:<port>` to VPN-routed `*.bstock-dev.com` (private
    address space) is denied by Chromium's LNA checks ("Permission was denied for
    this request to access the `local` address space") → BuyerInfo/docserv-meta
    style client fetches fail and error boundaries leak into captures (often only
    seconds AFTER load, so early screenshots look fine while videos catch the
    error). The template config now launches with
    `--disable-features=LocalNetworkAccessChecks` — keep it.

14. **seller-portal notes (FP-2369 run).** Route:
    `/sell/<accountId>/orders/<formattedPrettyId>/details` (UUID 308s to pretty).
    Data is SSR-prefetched via `spGsspMiddleware` → use the SSR-document rewrite
    (same `stampParcelMode` trick as cs-portal). Wait on the `Shipment` h2, never
    networkidle. UI baseline: for SELLER + BINDING the Carrier & Tracking block is
    ALREADY read-only pre-parcel-guard and the manual "Status: …" button is hidden
    (`showUpdateShipment` needs type !== BINDING) — the guard's only *visible* SP
    delta is on non-BINDING shipments (e.g. BUYER_PICKUP status button). Not every
    dev SERVICE login can view arbitrary sellers' SP pages — `isService` is
    supported, but the login also needs a service grant on that specific account.
    `mike.greiling+seller` (the seller demo default) failed on another seller's
    order (stuck LOADING then "Unexpected error"; it lacks a service grant on that
    account), while the broadly-granted evizi service account
    `qa.bstock+auto-dev-service-0312@gmail.com` rendered it fine. Rule: for
    cross-account SP/CSP viewing, use a broadly-granted service account (the evizi
    one), not just any service-flagged login. Buyer portal is buyer-scoped instead
    — capturing another buyer's order requires that buyer's own login (e.g.
    `thanh.nguyen+buyer.…` / `Pass!123` auto-consents through the `?code=`
    callback). Old (2023) order shipments may
    be embedded only in the ORDER service payload (`order.shipments`) and not
    findable via shipment-service `orderReferencePrettyId`/`orderId` params — grep
    the SSR HTML for the `_id` instead.

15. **encode.sh can abort mid-loop.** One failing ffmpeg encode (short/odd clip)
    used to kill the whole loop under `set -e` — later clips + combined.mp4 never
    produced. The template now continues past per-clip failures; if a clip is
    missing, check the printed warning.

16. **home-portal (buyer-portal) notes (FP-2370 run).** Buyer order-detail route:
    `/buy/user/<accountId>/orders/details/<orderUuid>` (order UUID `_id`, not the
    pretty id; wait on the `Shipments` h2). Data is SSR-prefetched
    (`gsspMiddleware` + `buyerOrderDetailsQuery.prefetch`) → the SSR-document
    rewrite (`stampParcelMode`) works unchanged. UI baseline: for portal=BUYER the
    fe-core `TrackingInfo` state machine resolves EVERY shipping type to
    DATA_READONLY/HIDDEN and `Actions.js` only shows the manual "Status: …" button
    for CS/SELLER — so the parcel read-only guard has NO buyer-visible delta on any
    shipment type (mode-null vs mode-PARCEL captures are byte-identical). To prove
    a stamp landed, assert on `__NEXT_DATA__` (`"_id":"<id>","mode":"PARCEL"`)
    rather than pixels. Also strip literal `"mode":null` before inserting — a later
    duplicate key would win at JSON.parse.

17. **`referencePrettyId` ≠ dedashed `formattedPrettyId`.** Formatted
    `5KR4C-OTL-K85Q` is stored as reference `5KR4C0TLK85Q` — the display form
    substitutes `O` where the stored id has `0` (and inserts dashes). Shipment
    service `?orderReferencePrettyId=` lookups with the dedashed *formatted* id
    silently return empty. Get the real `referencePrettyId` from the order
    payload (orders `findAll` returns both), never by string-munging the pretty id.

18. **Full-page screenshots paint sticky/fixed elements mid-image.** Playwright's
    `fullPage: true` stitches scrolled segments, so `position: sticky`/`fixed`
    chrome (e.g. cs-portal's "Cancel Order / Request Refund" action footer) gets
    baked wherever the viewport happened to be — floating awkwardly over the
    middle of the capture. Neutralize before any full-page shot:

    ```ts
    await page.evaluate(() => {
      for (const el of Array.from(document.querySelectorAll<HTMLElement>('*'))) {
        const pos = getComputedStyle(el).position
        if (pos === 'fixed' || pos === 'sticky')
          el.style.setProperty('position', 'static', 'important')
      }
    })
    await page.screenshot({ fullPage: true, ... })
    await page.reload()  // restore real layout if the page is used again
    ```

    `static` re-slots the element at its DOM position (usually the true bottom),
    which reads naturally; use `visibility: hidden` instead only if the element
    duplicates content. This applies to **element/locator screenshots too**, not
    just full-page: when the captured element is taller than the viewport,
    Playwright scroll-stitches it the same way and sticky chrome can occlude the
    middle of the crop (seen on a cs-portal order-detail element capture).
    Neutralize first whenever the captured region scrolls.

19. **Playwright's headless shell has no PDF viewer.** A demo whose click opens
    a PDF in a new tab renders an empty/blank popup headless. Run those specs
    headed: `test.use({ headless: false })` on the video spec (screenshots of
    non-PDF states can stay headless).

20. **Popup windows record as a separate video file.** With video recording on,
    a `window.open` popup produces its own `video-1.webm` next to the main
    page's clip. Produce one deliverable by concatenating main + popup with
    ffmpeg; trim the popup's white/black lead-in first (ffmpeg `blackdetect`
    finds the cut point).

21. **The bundled Chromium cannot reach the VPN at all — use `channel: 'chrome'`.**
    On a B-Stock workstation, Playwright's downloaded Chromium times out on
    *every* request to the dev network — not just subresource XHR, but a
    top-level navigation to the raw IP (`https://10.17.15.207/...`) — while
    `curl` from the same shell gets a response. So it is **not** an LNA/CORS
    policy (granting `local-network-access`, `--disable-features=
    LocalNetworkAccessChecks`, even `--disable-web-security` all fail
    identically); the corporate network agent simply doesn't admit the
    unsigned downloaded binary. Real Chrome is admitted. The template now pins
    `channel: 'chrome'` in **both** `playwright.config.ts` and
    `global-setup.ts` (the mint launches its own browser — pinning only the
    config leaves the mint broken). Symptom if you miss it: the callback page
    renders but `bstock_access_token` is never set, because the token exchange
    XHR silently hangs.

22. **accounts-portal now uses PKCE — an out-of-band code is unusable.**
    Sign-in mints a PKCE pair, stores it in `sessionStorage.oauth_challenge`,
    and the callback (`OAuth2RedirectPage`) requires the echoed `state.csrf` to
    match before exchanging the code with the stored `codeVerifier`. A
    server-minted code has no pair in the tab, so the page logs
    `login reauthorize {reason: lost-pair}` and restarts authorization —
    straight into the Turnstile the mint exists to avoid. `global-setup.ts` now
    mints the pair itself (`code_challenge`/`S256` + a `csrf` inside `state`)
    and seeds `sessionStorage` before navigating to the callback, using a
    `page.route`-stubbed blank page on the origin (loading a real
    accounts-portal route would mint and store a pair of its own and clobber
    the seeded one). Keep the shapes in sync with accounts-portal
    `src/app/helpers/auth/oauthChallenge.ts`.

23. **FusionAuth's hidden inputs come back HTML-escaped.** The scraped `state`
    carries `&quot;` entities, and because the scraped values are spread *after*
    our own params, that escaped copy replaces the real `state` and rides all
    the way to the callback — where `parseStateObject`'s bare `JSON.parse`
    returns null, so no csrf is found and the page reauthorizes. `global-setup`
    now unescapes every hidden value and re-asserts `state`,
    `code_challenge`, `code_challenge_method` afterwards.

24. **App Router flags are read on the SERVER — `forceFlags` cannot reach them.**
    `evalx` interception only patches the *client* SDK. A gate written as
    `await getRequestLocals().evaluateFlag(FeatureFlags.X)` (page.tsx, layouts,
    server components) is evaluated by `@launchdarkly/node-server-sdk` in the
    dev server and is completely unaffected. Use fe-core's **URL flag override**
    instead — it covers both sides and touches nothing in LaunchDarkly:
    - client (`useFlag`) reads it from `useSearchParams()`, so `?my-flag=true`
      on the URL is enough;
    - server (`evaluateFlag`) reads it from the **`x-search-params` request
      header**, which `contentSecurityPolicyMiddleware` normally sets.
    **But** home-portal's `src/proxy.ts` short-circuits `/buy/*` (and `/acct`,
    `/sell`, `/csportal`, …) with `NextResponse.next()` when
    `NODE_ENV === 'development'`, *before* that middleware runs — so under
    `npm run dev` the header never gets set and the override silently no-ops.
    Send it yourself from the browser:
    `await context.setExtraHTTPHeaders({ 'x-search-params': 'my-flag=true' })`.
    Overrides are gated to non-prod by `flagOverridesEnabled()`. A flag that
    doesn't exist in LD yet still overrides fine (the override is applied after
    the `FLAG_NOT_FOUND` default).

25. **`encode.sh` only trimmed a WHITE lead-in; real Chrome emits BLACK frames.**
    The original detected white by negating before `blackdetect`, which is right
    for a hydrating white page but leaves real Chrome's black pre-paint frames
    in place — the mp4 then opens on a black screen. `encode.sh` now measures
    both and seeks past whichever is longer. Always eyeball frame 0 after
    encoding (`ffmpeg -ss 0 -i out.mp4 -frames:v 1 f0.png`).

26. **`glab api ... -F file=@path` does NOT upload a file — use `--form`.**
    `-F/--field` reads the file's *contents* into a string field, and
    `POST projects/<id>/uploads` answers `HTTP 400`. `--form "file=@<path>"`
    sends real multipart and returns the `markdown` field to paste. Separately,
    `--method PUT ... --input body.json` needs an explicit
    `-H "Content-Type: application/json"` or GitLab replies `HTTP 415 The
    provided content-type '' is not supported` (nothing is written, so it is
    safe to retry).

27. **Assert on the navigation request, not `page.url()`, for external handoffs.**
    A feature that hands the top window to FusionAuth (`window.location.assign`)
    will usually *not* end on the URL it built: with no FusionAuth SSO cookie in
    an automation profile, `/account/two-factor/` bounces to
    `/oauth2/authorize` and then the hosted login. Capture the intended URL with
    a `page.on('request', …)` filter on `req.isNavigationRequest()` and assert
    on that; let the final landing be whatever it is (and screenshot it, since
    "we stopped at the login page" is itself the evidence).

28. **`bundle.sh` writes the zip to the REPO ROOT, which is not git-excluded.**
    `OUT="$ROOT/../<name>-bundle.zip"` lands next to `demo/`, and the scaffold
    only excludes `demo/` — so the zip shows up in `git status`. Move it out
    (e.g. to the deliverables folder) as soon as it is built.

29. **ffmpeg eats the `while read` loop's stdin — only clip 1 encodes.**
    `encode.sh` pipes the `find` results into a `while IFS= read -r webm` loop
    and calls ffmpeg inside it; ffmpeg reads stdin for its interactive keys and
    consumes the rest of the list, so iteration 2 gets a truncated (or empty)
    source path and the encode fails or writes garbage. **Every** ffmpeg
    invocation in a read loop needs `-nostdin` (the template now passes it on
    the detect, encode, and concat calls). Symptom: `videos/` has `01-*.mp4`
    and nothing else, with a "WARNING: encode failed" for a path that looks
    chopped.

30. **cs-portal bootstraps LD from the SSR payload — `forceFlags` is a no-op.**
    cs-portal renders `LDProvider … options.bootstrap` seeded from
    `pageProps.featureFlags`, which `gsspMiddleware` evaluates **server-side**.
    With a bootstrap in hand the client SDK never issues the `evalx` request
    that `forceFlags` intercepts, so the page's initial (and, with the stream
    aborted, only) flag set is whatever the server sent. Force it by rewriting
    the SSR document instead:

    ```ts
    await context.route('**/csportal/**', async (route) => {
      if (route.request().resourceType() !== 'document') return route.fallback()
      const response = await route.fetch()
      const html = await response.text()
      const marker = 'featureFlags":{'
      if (!html.includes(marker)) return route.fulfill({ response })
      return route.fulfill({
        response,
        body: html.replace(marker, `${marker}"${FLAG}":true,`),
        // length changed; drop it and let the browser work it out
        headers: { ...response.headers(), 'content-length': undefined as unknown as string },
      })
    })
    await context.route('**clientstream.launchdarkly.com**', (r) => r.abort())
    ```

    Inserting a key works even for a flag that does not exist in LD yet, and
    nothing is written to LaunchDarkly. Same document-rewrite shape as the
    `stampParcelMode` trick in #14/#16 — check any portal's flag plumbing before
    assuming evalx interception reaches it.

31. **Only `localhost:3030` is a registered redirect_uri on dev.** The dev
    FusionAuth client's sole localhost redirect is
    `http://localhost:3030/acct/login`; a mint against `:3031` answers
    `invalid_redirect_uri` (verified 2026-09-10). When 3030 is taken (another
    agent, another portal), don't fight for the port — run the app wherever, set
    `demo.config.mintUrl = 'https://bstock-dev.com'` (always registered), and
    `global-setup` mints there and transplants the `bstock_*` cookies onto
    `baseUrl`'s hostname with `context.addCookies`. Cookies are not port-scoped,
    so the local server accepts the token verbatim. Everything origin-sensitive
    in the mint (redirect_uri, callback host match, the origin the PKCE pair is
    seeded on) keys on `mintUrl`, not `baseUrl`.

32. **Mocked routes need `cache-control: no-store`.** A `route.fulfill` response
    with no cache headers is cacheable, and Chromium will replay a stale list
    read after a mutation — the table looks unchanged and the demo appears
    broken. Always send `headers: { 'cache-control': 'no-store' }` from a
    stubbed JSON route. Related: a page whose first paint comes from an SSR
    prefetch never issues the request your stub is waiting on — drive one
    client-side refetch (toggle a sort, change a filter) to make the stub bite.

33. **`hoverClick` is wrong for dropdown/menu items.** It smooth-`scrollIntoView`s
    its target before reading the bounding box; an anchored menu is still gliding
    when the mouse arrives, so the press lands on the row underneath and the
    click-outside handler closes the menu — silently, with nothing to assert on.
    Use `clickInPlace` (same eased cursor, no scroll) for anything already on
    screen and anchored: menu items, popovers, tooltips, floating panels. Opening
    the menu itself is fine with `hoverClick`; treat a dropdown open as flaky and
    re-open (up to ~3 tries) until the item is visible.

34. **A repo's `npm run type-check` may compile `demo/`.** home-portal's
    `tsconfig.json` includes `**/*.ts` and excludes only `common-ci` +
    `node_modules`, so the scaffolded `demo/` (and its `@playwright/test`
    imports) lands in the repo's type-check; cs-portal's include is scoped to
    `src` and does not. Before trusting a type-check result, confirm which case
    you are in and move `demo/` aside (or add it to `exclude` locally, reverting
    before commit) — otherwise you will chase errors that are not in the change
    under review. The template itself type-checks clean under
    `strict` + `noUncheckedIndexedAccess`; keep it that way when editing it.
