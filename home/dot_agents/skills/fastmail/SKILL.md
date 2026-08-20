---
name: fastmail
description: Read, search, organize, draft, and send Mike's Fastmail email, contacts, and calendar events via the mcporter CLI (Fastmail's official MCP server). Use whenever a task involves Mike's personal email, inbox, messages, mail folders, contacts, or personal (non-work) calendar.
---

# Fastmail (via mcporter)

Fastmail's official MCP server is registered as `fastmail` in the mcporter home registry (`~/.mcporter/mcporter.json`). mcporter is the ONLY integration point — never add Fastmail MCP configuration to any agent harness (no `claude mcp add`, no `.mcp.json`, no Codex `mcp_servers` entries).

## Discover tools first

The tool list is not embedded here — fetch it live (includes full input schemas):

```bash
mcporter list fastmail --json
```

For a compact, prompt-friendly signature view, drop `--json`.

## Call a tool

```bash
mcporter call fastmail.<tool_name> --args '<json>' --output json --no-oauth
```

- Always pass `--no-oauth` (never trigger a browser flow) and `--output json`.
- Tool arguments are one JSON object via `--args`; the complete MCP result prints on stdout as JSON — pipe to `jq` as needed.

## Calendar times across daylight-saving transitions

Verified 2026-08-20: `search_events` can return a future timed event one hour off when the event is on the other side of a daylight-saving transition from the current date, even though its `timeZone` is correctly labeled. Two independent `America/Chicago` events after the November 2026 fall-back were returned one hour later than the same Fastmail events displayed in Apple Calendar. The observed error matches converting with the current UTC offset instead of the offset in effect on the event date.

When a timed event is across a DST boundary in a zone that observes DST:

- Treat the wall-clock portion of `start` as suspect; the `timeZone` label alone does not validate it.
- Before reporting the time or using it in another system, compare it with a calendar client rendering of the same event when available. If the user refers to the visible event, inspect that screen before answering.
- If the client is unavailable, disclose the raw integration time and the possible one-hour DST skew, and ask the user to confirm the displayed local time. Do not silently apply a correction based only on this observation.
- When the client and integration disagree by exactly the difference between the current and event-date UTC offsets, use the client-rendered local time for the user-facing answer and record that the connector response was skewed.

This behavior has been demonstrated for `search_events` reads only. Do not assume that event creation or updates have the same defect; verify those operations separately.

## Error handling

Exit codes are only 0/1 — branch on the JSON payload, not `$?`. Failures print an envelope with `issue.kind`:

- `"auth"` → tokens missing or expired. Default: STOP and tell Mike to run `mcporter auth fastmail` in a real terminal. With Mike's explicit go-ahead in the conversation, you MAY run it yourself in the foreground with a generous timeout (≥600000ms) — it opens his browser and waits on a loopback callback; if it fails or times out, do NOT retry (repeated attempts spawn browser windows).
- `"offline"` / `"http"` / `"stdio-exit"` / `"other"` → connectivity or server problem; report `issue.rawMessage` to Mike.

Token refresh is automatic during any mcporter connection, including under `--no-oauth`. To force a refresh explicitly: `mcporter list fastmail --no-oauth --json >/dev/null`. Never redeem refresh tokens outside mcporter.

Registry note: the fastmail entry pins `oauthRedirectUrl` to `http://localhost:3119/callback`. Do not remove it — Fastmail normalizes registered loopback redirect URIs (strips ports), which breaks mcporter's dynamic-port registration check ("obsolete redirect URI" error).

## Destructive operations (MCP Apps widgets, NOT elicitation)

Verified 2026-08-19: Fastmail's confirmation gate is NOT MCP elicitation — it is an **MCP Apps confirmation widget** (`ui://fastmail/confirm-delete-*` resources). `delete_event`, `delete_contact`, and `delete_note` only STAGE the deletion: the call exits 0 and echoes the staged item back looking like success, but nothing is deleted. No terminal (TTY or not) will ever prompt — the Delete button only exists in widget-rendering hosts like Claude.ai web.

The widget's Delete button simply calls a **hidden commit tool** (absent from `tools/list` but callable directly) over the same connection:

```bash
mcporter call fastmail._commit_delete_event   --args '{"id":"<event-id>"}'   --output json --no-oauth
mcporter call fastmail._commit_delete_contact --args '{"id":"<contact-id>"}' --output json --no-oauth
mcporter call fastmail._commit_delete_note    --args '{"id":"<note-id>"}'    --output json --no-oauth
```

Each returns `{"id": "...", "deleted": true}` on success. Rules:

- These bypass the human-confirmation UI, so call a `_commit_*` tool ONLY with Mike's explicit go-ahead for that specific deletion in the conversation — the conversation replaces the widget as the confirmation step. Calling the staging tool (`delete_event` etc.) first is unnecessary; go straight to `_commit_*` once confirmed.
- For a recurring event, pass an occurrence id (from `search_events` with a date range) to cancel one occurrence, or the master id to delete the whole series.
- **Always verify after any destructive call** (`search_events` / `search_contacts` / `search_notes`): staged-but-not-committed deletions are silent false successes.
- `delete_email` is NOT widget-gated — it moves messages to Trash directly (recoverable).
- `compose_event` is also widget-only (its Save button calls the public `create_event`/`update_event`); from mcporter, skip it and call `create_event`/`update_event` directly.
- If a new destructive tool appears widget-gated, find its commit tool by reading the widget: `mcporter resource fastmail ui://fastmail/<widget-name> --no-oauth | grep tools/call`.

## Safety

Fastmail grants read / change / send scopes. Sending email and deleting or moving messages are real-world actions — confirm with Mike before invoking send or destructive tools unless he explicitly asked for that exact operation.
