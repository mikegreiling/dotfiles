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
