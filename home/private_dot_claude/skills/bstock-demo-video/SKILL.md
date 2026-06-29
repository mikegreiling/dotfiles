---
name: bstock-demo-video
description: Use this skill to record a demonstration video of a B-Stock frontend feature or change with Playwright, and to produce a replayable QA script bundle. Triggers include "create a demo video", "record the feature", "demo this change/MR/ticket", "screen recording for the MR/Jira", "show the new UI", "make a QA playwright script", or any request to visually demonstrate a frontend change in a B-Stock portal (home/seller/cs/accounts/cops). Drives the real dev backend, mints a session past Cloudflare Turnstile, forces LaunchDarkly flags, hides dev overlays, and records a natural-cursor walkthrough.
version: 0.1.0
---

# B-Stock Demo Video

Record a clean, natural-looking demo video of a B-Stock portal feature and bundle
the **replayable Playwright script** for QA. The hard parts (auth past Turnstile,
forcing flags, finding real data, cursor/scroll polish, ffmpeg) are pre-solved in
the bundled template; per task you mostly fill **parameters** and author a thin
scenario.

> **This skill is a work in progress.** If you discover a new pitfall, a better
> selector, a setup/teardown pattern, or anything that would make the next run
> smoother, **propose a concrete edit to this skill and offer to commit it** (it's
> version-controlled in chezmoi — see step 12). Don't silently work around gaps.

## What it is NOT
Not limited to "open a modal, scroll, close." That's the *shipped example*. The
core is reusable interaction primitives + a parameterized scenario you author for
**any** frontend change — touring the **window** or **any** scrollable region
(modal body, side panel, table, drawer), interacting, then finishing.

## Bundled assets
- `assets/demo-template/` — the deterministic Playwright project copied into
  `<repo>/demo/`. Key files: `demo.config.ts` (THE parameter file you fill),
  `demo.spec.ts` (worked parcel example = a pattern to copy), `human.ts` (cursor +
  `tour`/`scrollModal`/`closeModal`/`confirmOrClose`), `global-setup.ts` (Turnstile
  bypass mint), `ld-intercept.ts` (`forceFlags`), `overlays.ts` (`hideChrome`),
  `discover.spec.ts` (refresh stale IDs), `setup.ts`/`teardown.ts` (stubs),
  `encode.sh`/`bundle.sh`, `README.md`.
- `scripts/scaffold.sh` — lay the template into a repo + git-exclude + install.
- `references/` — `runbook.md` (deep how/why), `pitfalls.md` (read this),
  `fusionauth-client-ids.md`, `setup-teardown.md` (future seeding).

**Read `references/pitfalls.md` and skim `references/runbook.md` before running.**

## Workflow
1. **Scope.** Identify: repo/worktree, the MR + Jira ticket, portal + route(s),
   LD flag(s), and the subject record(s) (listing/order/dispute/…). Ask only what
   isn't derivable. If the right record doesn't exist yet, see
   `references/setup-teardown.md` — automated seeding is a **future stub**; for now
   seed manually (or via existing `fe-scripts`) or ask the user, and flag the gap.
2. **Prereqs.** VPN up. Ensure an app at `baseUrl` has the feature: pre-merge run
   the branch dev server (e.g. `npm run dev` → :3030); post-merge point `baseUrl`
   at the deployed env. Confirm reachable.
3. **Scaffold.** `bash scripts/scaffold.sh <repo>` → copies template to
   `<repo>/demo`, git-excludes it, installs Playwright.
4. **Fill `demo.config.ts`** — env, baseUrl, buyer email, `forceFlags`, `size`,
   `records` (the non-deterministic IDs), `scenarios` (+ `submit` opt-in). Set
   `BSTOCK_DEMO_PASSWORD` (or `demo/creds.json`) from `-docs/dev-test-credentials.md`.
5. **Author `demo.spec.ts`** for the feature by composing `human.ts` (navigate →
   `tour` the relevant region → interact → `confirmOrClose`). Copy the parcel
   example's shape; keep IDs in `records`.
6. **Run** `(cd demo && npx playwright test)`. If a record is stale (404 / empty),
   `npx playwright test discover.spec.ts`, refresh `records`, re-run.
7. **Encode** `npm run encode` → `videos/*.mp4` (+ `combined.mp4`). Spot-check a
   frame: no white start, no dev overlays, centered cursor, full tour, visible close.
8. **Bundle** `npm run bundle` → `…-bundle.zip` (verify `node_modules` NOT in it).
9. **Route — video + script to BOTH MR and Jira.** MR: upload the video and zip
   via `mcp__gitlab__upload_markdown` and embed/link in the MR (use
   `bstock-engineering` / `bstock-merge-requests`). Jira: **manual** — `SendUserFile`
   the video + zip to the user with a paste-ready summary; they drag both onto the
   ticket (acli can't upload attachments; no Jira attachment MCP tool).
10. **Report** caveats: replay prereqs (VPN/creds/Node/baseUrl), param staleness,
    and what was/wasn't submitted.
11. **Self-revise.** Propose concrete skill edits for anything you had to figure
    out, and offer to apply + commit them.
12. **Commit (chezmoi).** Skill files live under chezmoi — per `dotfiles-workflow`:
    edit live under `~/.claude/skills/bstock-demo-video/`, then `chezmoi add` and
    commit to `~/.local/share/chezmoi` (straight to `main`).

## Guardrails
- Stop before the real submit unless a scenario sets `submit:true` on a
  disposable/seeded record. Don't mutate shared dev records others rely on.
- Never embed secrets in the project/zip (password via env/`creds.json`).
- Don't commit `demo/` or `@playwright/test` into the feature MR.

## Cross-references
- `bstock-engineering` — MR/Jira ops, `glab`/GitLab MCP, project IDs.
- Memory `project_glob4588_parcel_demo_listings` — the worked example's IDs/buyer.
- `references/runbook.md` — full detail behind every step above.
