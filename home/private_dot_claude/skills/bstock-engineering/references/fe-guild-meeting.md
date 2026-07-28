# FE+BE Guild Meeting Automation

Mike runs the bi-weekly FE+BE guild meeting (colloquially still "FE Guild"). This file canonizes the delegated actions: **(1) the pre-meeting agenda reminder**, **(2) the interactive post-meeting workflow**, and **(3) the quarterly archival sweep**. Structure facts verified live 2026-07-28 against page version 427.

## Stable facts

- **Charter page**: **"FE+BE Guild Charter"** — pageId `2345959440`, space `EN`, URL `https://bstock.atlassian.net/wiki/spaces/EN/pages/2345959440` (renamed from "Front End Guild Charter" + preamble rewritten to reflect the FE+BE merger, v428, 2026-07-28). **Owner: Mike** (Mike also holds Confluence admin).
- **Archive page**: "Historical Guild Meeting Notes" — pageId `3357933581`, also **owned by Mike**. Ryan's tradition: older meeting sections get moved here verbatim; continued via the quarterly sweep below.
- **Cadence**: every other **Tuesday**, morning (shifted from alternate Wednesdays late June 2026). Compute next meeting = newest dated section + 14 days; sanity-check it's a Tuesday. No calendar access yet — **always confirm the computed date with Mike** (meetings get moved for conflicts/holidays; the calendar event "FE+BE Guild meeting (bi-weekly)" is the source of truth only he can see).
- **Slack channel**: `#fe-guild` = `C04225G5QCS`.
- Scope covers FE **and** BE topics (BE Guild merged in).

## Page anatomy (do not deviate)

Under `# Meeting Topics / Notes` → `## Recording Policy`, sections run newest-first:

1. **`## Next Meeting`** — the accumulation slot where people add agenda rows between meetings. Canonical empty state = table header (`**Topic (FE and BE topics)** | **Outcome** | **Owner**`) plus three empty rows.
2. **`## YYYY-MM-DD`** dated sections, each: same table with filled rows, then the Zoom recording smartlink on its own line, then `Passcode: <passcode>`. Owners/people are **mention nodes**, not plain text.

Storage format (XHTML) is the ONLY safe read/write representation — markdown is lossy on smartlinks/mentions. The body is ~180KB: always redirect to a file, extract regions by grep/offset, never dump into context.

## Action 1 — pre-meeting agenda reminder

1. Read the `## Next Meeting` slot (region-extract, not whole page) and note queued topics.
2. Compose for `#fe-guild`, e.g.: "Reminder: guild meets this Tuesday (Aug 4). Add topics to the agenda: <page URL> — N topic(s) queued so far." Live `<!here>` only if Mike approves it verbatim (slack-workflow.md mention policy).
3. **Scheduling is sending** — Mike approves exact text + time (default suggestion: morning before, ~9am CT), then `slack_schedule_message` to `C04225G5QCS`. Report the `scheduled_message_id`.

## Action 2 — post-meeting workflow (interim, hands-on)

Trigger: Mike says something like "run the guild post-meeting workflow". No Zoom/email/calendar access exists yet, so the agent drives an interactive checklist, prompting Mike for what only he can see:

1. **Read the page** (acli, storage → file) and validate anchors: `## Next Meeting` heading + canonical table present, newest dated section identified. Report the queued agenda rows.
2. **Prompt Mike for the inputs**:
   - the meeting date being processed (default: the most recent expected Tuesday — confirm, don't assume);
   - Zoom recording **share URL + passcode** (from the Zoom email; treat passcodes as opaque — shell-hostile chars);
   - the **transcript and/or AI summary** (pasted or a file path);
   - whether the **next meeting is on schedule** (+14d Tuesday) or moved/cancelled;
   - which queued topics were **actually discussed** — undiscussed rows **carry forward** into the fresh Next Meeting table rather than getting buried under the dated header.
3. **Transform** (touch ONLY the Next Meeting section; never edit older dated sections):
   - Rename `## Next Meeting` → `## YYYY-MM-DD`.
   - Fill Outcome cells from the transcript — terse, decision-focused (what was decided + who acts), matching prior sections' style; keep/add Owner mention nodes; drop leftover empty rows; add rows for substantive unlisted topics discussed.
   - Below the table: the Zoom share URL as a plain link (Confluence smartlinks it on render), then `Passcode: <passcode>`.
   - Insert a fresh `## Next Meeting` empty-state block above the new dated section, seeded with any carry-forward rows.
4. **Quarterly archival check** (see Action 3) — if due, fold it into the same edit.
5. **Confirm before writing** — show Mike the composed dated section (transcript ambiguities as questions, not guesses). Shared team page: no write without his OK on the content.
6. **Write and verify**: PUT the full storage body with version+1 via `confluence-api` (recipe below), then re-read the region and confirm: heading renamed, fresh slot present, recording+passcode in place, byte-identical below the edit. Report the page URL.

```bash
acli confluence page view --id 2345959440 --body-format storage --json > /tmp/guild.json   # read
v=$(confluence-api GET '/api/v2/pages/2345959440' | jq '.version.number')                  # write:
jq -n --argjson v "$((v + 1))" --arg t "<current title>" --rawfile b /tmp/guild-updated.html \
  '{id:"2345959440", status:"current", title:$t, version:{number:$v},
    body:{representation:"storage", value:$b}}' | confluence-api PUT '/api/v2/pages/2345959440'
```

**Collab-editing caveat**: API publishes rebase any open editor drafts; worst case is a messy merge in the touched region, never silent data loss (version history restores anything). Prefer quiet windows (right after the meeting / evening), keep the write atomic, and ask Mike to publish/discard his own unpublished draft first if the page banner shows one. **Draft-detection guard (unverified — probe when the API token exists)**: v1 exposed a `draftVersion` expansion and v2 has a draft-fetch variant (`get-draft`); if fetching the draft succeeds and its version/content differs from published, someone has pending changes — warn before writing. Verify which of these actually works on this tenant, then promote the working one into the pre-write checklist here.

## Action 3 — quarterly archival sweep

Tradition inherited from Ryan Jenkins, continued on Mike's direction (2026-07-28). Policy: the charter retains the trailing **~9 months** of dated sections (12 months is the hard ceiling — Mike: "12 at the maximum, possibly as low as 9; that's plenty"); everything older moves **verbatim** (exact storage-format cut, order preserved) to "Historical Guild Meeting Notes" (`3357933581`), slotted under the year headings that page already uses. Sweep ~quarterly, folded into a post-meeting edit when due (one atomic write per page: cut from charter, prepend to archive), with Mike's confirmation on the exact sections moving. Before the FIRST sweep, inspect the archive page's storage structure and mirror its existing layout — do not invent a new one.

## Operational lessons (verified 2026-07-28, first live write cycle)

- **Read via acli, write via `confluence-api`.** The v2 GET with `body-format=storage` through `confluence-api` (basic auth) **hangs for minutes** on this 180KB page — while `acli confluence page view --body-format storage --json` returns in seconds, and `confluence-api PUT` works fine. The metadata-only GET (`/api/v2/pages/<id>`, no body param) is also fast — use it for the version number.
- **Expect harmless normalization noise on write**: Confluence canonicalizes storage format, e.g. reordering `<ac:parameter>` children inside Jira-issue macros throughout the page. A byte-diff of sent-vs-read-back will show these; they are semantics-preserving. Verify with **targeted region checks** (preamble strings, section headings, tail text) rather than whole-body hashes.
- **Edit recipe that worked**: exact-string replacements each asserted to occur exactly once, whole-`<li>` removals located by `local-id`, and a pre-write assert that everything from `Meeting Topics` onward is byte-identical to the fetched original. Preserve existing `local-id` attributes; omit them on new nodes.
- **Draft-detection guard (partial)**: `GET /api/v2/pages/<id>?get-draft=true` (no body) is fast and returns a draft object — but the draft object **persists after publishing** with its own version counter, so existence ≠ pending changes. Body-compare is impractical (the body-format draft fetch hangs). Best available signal: compare the draft's version timestamp against the published version's; treat as heuristic, and keep relying on quiet-window timing + Mike confirming his editor is closed.

> **Auth**: personal Atlassian API token, minted 2026-07-28, keychain service `atlassian-api-token` (annual expiry — re-mint and re-store with `security add-generic-password -U …` when it lapses). `confluence-api` reads it in-process; never print it.

## Notes for future sessions

- Zoom email parsing: share URL (`bstock.zoom.us/rec/share/...`) + passcode arrive verbatim in the recording email; passcodes contain `^ ! $ *` — never interpolate unquoted.
- Future upgrades parked in the Things project "FE Guild Meeting Automation" (`JtnuWw8T89sRpNYv9kNifS`): Zoom MCP (blocked on IT-granted developer role), Apple Mail/Calendar scripting for email+calendar reads (zero-OAuth local path), full deterministic `guild-charter` helper script (template-splice edits driven by a small JSON payload so no agent ingests the 180KB body). Keep that project in sync via the `things` CLI.
- If the newest dated section is ≥3 weeks old, a meeting was skipped or moved — ask Mike, never guess the date.
