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
