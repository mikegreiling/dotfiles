# FE Guild Meeting Automation

Mike runs the bi-weekly Front End Guild meeting. This file canonizes the two actions he delegates: **(1) the pre-meeting agenda reminder** and **(2) post-meeting processing** of the Confluence notes page. Structure facts below were verified live 2026-07-24 against page version 426.

## Stable facts

- **Confluence page**: "Front End Guild Charter" — pageId `2345959440`, space `EN` (Engineering), cloudId `8fd1c100-2018-43ac-bdc1-ca69369799c3`, URL `https://bstock.atlassian.net/wiki/spaces/EN/pages/2345959440/Front+End+Guild+Charter` (tiny: `/wiki/x/EIDUiw`). Parent: "Guilds" (`2345435343`). Older years get pruned occasionally to "Historical Guild Meeting Notes" (`3357933581`) — that archival is manual/out of scope.
- **Cadence**: every other **Tuesday**, morning. The schedule shifted from alternate Wednesdays to Tuesdays in late June 2026 — compute the next meeting as **newest dated section + 14 days**, and sanity-check the result is a Tuesday; if not, ask Mike rather than guessing.
- **Slack channel**: `#fe-guild` = `C04225G5QCS`.
- **Meeting scope**: despite the FE name, the meeting covers BE topics too (BE Guild merged in — hence the "Topic (FE and BE topics)" column header).

## Page anatomy (do not deviate)

Under `# Meeting Topics / Notes` → `## Recording Policy`, the sections run newest-first:

1. **`## Next Meeting`** — the accumulation slot where people add agenda rows between meetings. Canonical empty state is the table header plus three empty rows:

   ```
   ## Next Meeting

   | **Topic (FE and BE topics)** | **Outcome** | **Owner** |
   | --- | --- | --- |
   |  |  |  |
   |  |  |  |
   |  |  |  |
   ```

2. **`## YYYY-MM-DD`** dated sections (newest first), each: the same table with real rows (Topic | Outcome | Owner), then the Zoom recording as a **smartlink node** on its own line, then `Passcode: <passcode>`. Owners and people referenced in outcomes are **mention nodes**, not plain text.

## Action 1 — pre-meeting agenda reminder

Trigger: Mike asks for the guild reminder (or a scheduled automation does).

1. Compute the next meeting date (newest dated section + 14d). Read the current `## Next Meeting` table and note any topics already added.
2. Compose the reminder for `#fe-guild`. Template (adjust topic line to reality):

   > Reminder: FE Guild meets this Tuesday (Jul 21). Add topics you'd like discussed to the agenda: https://bstock.atlassian.net/wiki/spaces/EN/pages/2345959440/Front+End+Guild+Charter — N topic(s) queued so far / the agenda is currently empty.

   A live `<!here>` is allowed **only** if Mike approves it in the exact text (see slack-workflow.md mention policy).
3. **Scheduling is sending** — get Mike's explicit OK on text + send time (default suggestion: the morning before, ~9am CT), then `slack_schedule_message` to `C04225G5QCS`. Report the `scheduled_message_id`; descheduling/rescheduling goes through `slack-api.sh scheduled-*`.

## Action 2 — post-meeting processing

Trigger: Mike provides the Zoom recording email (share link + passcode) and a transcript/summary/his notes. Interim workflow: he pastes the email content; a future automation may capture it from mail.

1. **Read the page** with `getConfluencePage` `contentFormat: "html"` — HTML is round-trip safe and preserves smartlink/mention nodes; markdown is lossy and must never be used for an edit cycle. The page is ~56KB and overflows the tool-result limit: the result lands in a file — extract the needed regions by offset/grep, don't read it all into context.
2. **Transform** (touch ONLY the `## Next Meeting` section; never edit older dated sections):
   - Rename `## Next Meeting` → `## YYYY-MM-DD` (the meeting's actual date).
   - Fill the table from the transcript: concise decision-focused **Outcome** text per topic (what was decided + who acts, matching the terse style of prior sections), keep/add **Owner** mention nodes. Delete leftover empty rows. Add rows for substantive topics discussed that weren't pre-listed.
   - Below the table: the Zoom share link (as a plain URL — Confluence converts it to a smartlink on render) and `Passcode: <passcode>` on its own line.
   - Insert a fresh `## Next Meeting` empty-state block (template above) immediately before the new dated section.
3. **Confirm before writing**: this is a shared team page — show Mike the composed dated section (and note any transcript ambiguities as questions, not guesses) before calling `updateConfluencePage`.
4. **Write and verify**: `updateConfluencePage`, then re-read the section region to confirm the structure landed (heading renamed, fresh Next Meeting slot present, recording+passcode in place). Report the page URL.

## Notes for future sessions

- Zoom email parsing: the recording email contains the share URL (`bstock.zoom.us/rec/share/...`) and passcode verbatim — passcodes contain shell-hostile characters (`^`, `!`, `$`, `*`); treat as opaque strings, never interpolate unquoted.
- Transcript ingestion via Zoom MCP/API is parked as a Someday task in the Things project "FE Guild Meeting Automation" (`JtnuWw8T89sRpNYv9kNifS`) — keep that project in sync via the `things` CLI as pieces get built or refined.
- If the newest dated section is ≥3 weeks old, a meeting was likely skipped or the cadence moved again — ask Mike before assuming the next date.
