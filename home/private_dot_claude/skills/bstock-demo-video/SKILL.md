---
name: bstock-demo-video
description: Use this skill to build a deterministic Playwright workflow that demonstrates a B-Stock frontend feature/change OR reproduces a frontend bug, records a polished video of it, and packages that script as a self-contained bundle others can replay on their own dev/QA workstation. Triggers include "create a demo video", "record the feature", "show the new UI", "demonstrate this change", "reproduce this bug with a video", "make a deterministic repro", "make a replayable QA/Playwright script", or any request to visually capture frontend behavior in a B-Stock portal (home/seller/cs/accounts/cops). Drives the real dev backend, mints a session past Cloudflare Turnstile, forces LaunchDarkly flags, hides dev overlays, and records a natural-cursor walkthrough. Does NOT post/attach artifacts anywhere — distribution is out of scope.
version: 0.1.0
---

# B-Stock Demo Video

Build a **deterministic Playwright workflow** that drives a B-Stock portal to
**demonstrate a feature/change or reproduce a bug**, record a clean video of it to
the standards below, and **package the script as a shareable bundle** another
engineer can replay on their own dev/QA workstation. The hard parts (auth past
Turnstile, forcing flags, finding real data, cursor/scroll polish, ffmpeg) are
pre-solved in the bundled template; per task you mostly fill **parameters** and
author a thin scenario.

## Scope
- **In scope:** the Playwright workflow, the recorded video (to the styling
  standards), and the portable bundle for local replay by others.
- **Out of scope:** *distributing* the artifacts. Do **not** upload/attach/post the
  video or bundle to a GitLab MR, Jira ticket, Slack, etc. Produce them and hand
  them to the user; how they share is their call.
- A scenario can equally **demonstrate** (happy path) or **reproduce a bug** (drive
  the exact steps that trigger it and let the video capture the broken behavior).
- Not limited to "open a modal, scroll, close" — that's the *shipped example*. The
  core is reusable interaction primitives + a scenario you author for **any**
  frontend change, touring the **window** or **any** scrollable region.

> **This skill is a work in progress.** If you discover a new pitfall, a better
> selector, a setup/teardown pattern, or anything that would make the next run
> smoother, **propose a concrete edit to this skill and offer to commit it** (it's
> version-controlled in chezmoi — see step 12). Don't silently work around gaps.

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
1. **Scope.** Identify: repo/worktree, portal + route(s), LD flag(s), the subject
   record(s) (listing/order/dispute/…), and what to capture (a feature's happy path
   or the precise steps that reproduce a bug). Ask only what isn't derivable. If the
   right record doesn't exist yet, see `references/setup-teardown.md` — automated
   seeding is a **future stub**; for now seed manually (or via existing `fe-scripts`)
   or ask the user, and flag the gap.
2. **Prereqs.** VPN up. Ensure an app at `baseUrl` has the change: pre-merge run the
   branch dev server (e.g. `npm run dev` → :3030); post-merge point `baseUrl` at the
   deployed env. Confirm reachable.
3. **Scaffold.** `bash scripts/scaffold.sh <repo>` → copies template to
   `<repo>/demo`, git-excludes it, installs Playwright.
4. **Fill `demo.config.ts`** — env, baseUrl, afterLogin, `forceFlags`, `size`,
   `records` (the non-deterministic IDs), `scenarios` (+ `submit` opt-in). Resolve
   the login identity (see **Credentials**) — never hardcode it.
5. **Author `demo.spec.ts`** by composing `human.ts` (navigate → `tour` the relevant
   region → interact → `confirmOrClose`). Copy the parcel example's shape; keep IDs
   in `records`.
6. **Run** `(cd demo && npx playwright test)`. If a record is stale (404 / empty),
   `npx playwright test discover.spec.ts`, refresh `records`, re-run.
7. **Encode** `npm run encode` → `videos/*.mp4` (+ `combined.mp4`). Spot-check a
   frame: no white start, no dev overlays, centered cursor, full tour, visible close.
8. **Bundle** `npm run bundle` → `…-bundle.zip` (verify `node_modules` NOT in it) —
   this is the portable artifact others replay locally.
9. **Hand off.** Give the user the video(s) + the bundle (e.g. `SendUserFile`). Stop
   there — **do not** attach/post them to an MR, ticket, or chat (out of scope).
10. **Report** caveats: replay prereqs (VPN/creds/Node/baseUrl), param staleness,
    and what was/wasn't submitted.
11. **Self-revise.** Propose concrete skill edits for anything you had to figure out,
    and offer to apply + commit them.
12. **Commit (chezmoi).** Skill files live under chezmoi — per `dotfiles-workflow`:
    edit live under `~/.claude/skills/bstock-demo-video/`, then `chezmoi add` and
    commit to `~/.local/share/chezmoi` (straight to `main`).

## Credentials (source-agnostic — the agent obtains them, the skill doesn't assume)
A run needs **one login identity** (email + password) for a dev test account on the
target env. The skill makes **no assumption** about which account or where it lives.
`global-setup.ts` resolves it at runtime (first match wins):
1. env vars `BSTOCK_DEMO_EMAIL` + `BSTOCK_DEMO_PASSWORD`;
2. a git-ignored `demo/creds.json` → `{"email":"…","password":"…"}`.

**Your job as the agent**: get that pair from the user organically, however they
offer it — they may point you at a local credentials file and say *which* account to
use (read it then), paste the pair directly, or have already exported the env vars.
Then supply it via option 1 or 2. Never hardcode a path, never assume a file exists,
never commit the secret. These are throwaway dev-env accounts; the only requirement
is the account can see the subject resources (and has a destination address if the
feature needs one). The identity is intentionally **not** in `demo.config.ts`.

## Guardrails
- Stop before the real submit unless a scenario sets `submit:true` on a
  disposable/seeded record. Don't mutate shared dev records others rely on.
- Never embed secrets in the project/zip (creds via env/`creds.json`).
- Don't commit `demo/` or `@playwright/test` into the target repo's tracked tree.

## Cross-references
- `bstock-engineering` — general B-Stock context (project IDs, `glab`/GitLab + Jira
  tooling) if a task needs it. (Distribution of these artifacts is still out of scope.)
- `references/runbook.md` — full detail behind every step above.
- A local memory note may hold worked-example record IDs/accounts (e.g. the parcel
  demo) — use it only if present.
