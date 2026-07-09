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

4. **No in-app LD flag override.** Force flags via evalx interception + clientstream
   abort (`forceFlags`). There is no query-param/localStorage toggle for most flags.

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
    delta is on non-BINDING shipments (e.g. BUYER_PICKUP status button). A dev
    SERVICE login can view any seller's SP pages (`isService` is supported) — handy
    when a specific seller's password isn't on file. Old (2023) order shipments may
    be embedded only in the ORDER service payload (`order.shipments`) and not
    findable via shipment-service `orderReferencePrettyId`/`orderId` params — grep
    the SSR HTML for the `_id` instead.

15. **encode.sh can abort mid-loop.** One failing ffmpeg encode (short/odd clip)
    used to kill the whole loop under `set -e` — later clips + combined.mp4 never
    produced. The template now continues past per-clip failures; if a clip is
    missing, check the printed warning.
