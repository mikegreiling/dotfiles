---
name: fastmail
description: Read, search, organize, draft, and send Mike's Fastmail email, contacts, and calendar events via mcporter; use CardDAV for Apple-compatible contacts and Keychain-authenticated CalDAV for raw event times and alarms unavailable through MCP. Use whenever a task involves Mike's personal email, inbox, messages, mail folders, contacts, or personal (non-work) calendar.
---

# Fastmail (via mcporter)

Fastmail's official MCP server is registered as `fastmail` in the mcporter home registry (`~/.mcporter/mcporter.json`). mcporter is the ONLY MCP integration point — never add Fastmail MCP configuration to any agent harness (no `claude mcp add`, no `.mcp.json`, no Codex `mcp_servers` entries). Direct CardDAV and CalDAV are the approved exceptions below, using their own scoped Keychain app passwords, not MCP tokens.

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

## Contacts: writes go through CardDAV, not the MCP tools

Mike reads his contacts in **Apple Contacts**. The MCP contact writers emit vCards with an empty `N:;;;;` and `TYPE`-less `TEL`/`EMAIL`, which Apple renders as a *company* card named after the ORG with a phone field labeled "PROP-ID". `scripts/carddav-contact` writes clean vCard 3.0 that Fastmail stores verbatim. Routing rules:

- **Read / lookup** — MCP `search_contacts` is fine. Its ids are not CardDAV UIDs.
- **Create** — `scripts/carddav-contact new …` ONLY. Never MCP `create_contact`.
- **Rename or any structural edit** — `carddav-contact get <name> > c.vcf` → edit → `carddav-contact put c.vcf`. Never pass `name` to MCP `update_contact` (it wipes `N`).
- **Add/remove one email or phone** — prefer `carddav-contact`. An MCP `update_contact` delta is tolerable only if `name` is not passed and `notes` is not set to `""`.
- **Delete** — `carddav-contact delete <uid>`, only after Mike explicitly confirms that contact (or the MCP `_commit_delete_contact` path documented below).

Credentials: a Contacts-scoped Fastmail app password in the login keychain, service `fastmail-carddav`. If the script reports HTTP 401 or "no credentials", read `references/carddav-credentials.md` and ask Mike to re-mint — do not work around it or try another credential.

- `references/carddav-contacts.md` — load before hand-editing a vCard, hand-rolling curl against CardDAV, or deciding whether an MCP contact write is safe (verified failure modes, `--help`, endpoint, id mapping).
- `references/carddav-credentials.md` — load on any 401 / missing-credential failure, or when setting the skill up on a new Mac (provenance, scope, re-mint runbook).

## Calendars: CalDAV for raw times and event alarms

Use `scripts/caldav-calendar` for read-only calendar discovery, bounded event queries, and individual event reads. It reads the macOS Keychain service `fastmail-caldav`, account `mike@greiling.me`; the dedicated app password is intended for Calendars (CalDAV) access. Read `references/caldav-credentials.md` before using CalDAV, setting it up on another Mac, or implementing calendar writes.

- Verified live on 2026-08-29: calendar discovery, REPORT queries, and GET work. One Business event exposes `VALARM` with `ACTION:DISPLAY` and `TRIGGER:-PT15M` through both query and GET. This proves alarm reads work, not that all historical alarms survived.
- The current MCP event tools have no explicit alarm fields. Do not claim a reminder was set merely because MCP created an event. Use CalDAV to inspect explicit alarms; default/client-specific notifications and delivery remain separate checks.
- Verified with synthetic events on 2026-08-29: CalDAV creates DISPLAY/EMAIL alarms; changing, removing, restoring a DISPLAY alarm and overriding one recurring occurrence's time/alarm work. Stale ETags are rejected with HTTP 412. MCP description/time edits preserved the tested explicit relative alarm. An EMAIL reminder arrived one second after its scheduled trigger. Mike confirmed both Apple Calendar and Fastmail iPhone DISPLAY notifications at the scheduled minute in a coordinated retest. For short-notice device tests, confirm the event and alarm have synced before the trigger. Mike confirmed the earlier misses were late sync: those events did not appear in Apple Calendar until he manually refreshed after their alert times. The helper still has **no write commands**: implement authorized PUTs using the credential and preservation rules in the reference. Do not modify a real event just to test access.
- Fastmail's bulk ICS export/import limitation is not a CalDAV limitation. Inspect an authenticated CalDAV resource for alarms rather than inferring their presence or absence from a bulk export.
- Missing/denied Keychain access or HTTP 401/403: stop and ask Mike; do not search other secret stores, reuse the Contacts credential, or fall back to MCP OAuth.

## Calendar times across daylight-saving transitions

Verified 2026-08-29: Google Business ICS and Fastmail CalDAV agree exactly on all 469 expanded occurrences' UID, start/end instants, title, and all-day status. MCP returned 162 one hour late and 307 correctly. Controlled winter creation stored December 15, 2026 at 09:00 America/Chicago (15:00Z); Apple Calendar showed 09:00, but MCP returned 10:00 with America/Chicago. Summer/winter, both DST boundaries, and two fall-back 01:30 instants reproduce a **read representation defect**. Behavior is consistent with applying the current offset instead of the event-date offset; the server implementation has not been inspected.

When a timed event is across a DST boundary in a zone that observes DST:

- Treat the wall-clock portion of `start` as suspect; the `timeZone` label alone does not validate it.
- Before reporting the time or using it in another system, compare with the raw CalDAV event and/or a calendar client rendering of the same event. Interpret TZID/VTIMEZONE using the event date, never today's UTC offset; preserve named-zone/local-time intent for recurring events and date-only values for all-day events. If the user refers to the visible event, inspect that screen before answering.
- A resolved CalDAV instant plus event-date timezone is authoritative even without a UI session; do not substitute MCP's shifted clock reading. If neither raw CalDAV nor a client is available, disclose uncertainty and ask for confirmation. Do not silently apply a correction based only on this observation.
- When the client and integration disagree by exactly the difference between the current and event-date UTC offsets, use the client-rendered local time for the user-facing answer and record that the connector response was skewed.

Creation and time updates were independently tested and stored the requested local time correctly. Pass MCP `start` as an offset-free local value (e.g. `2026-12-15T09:00:00`) with separate `timeZone: "America/Chicago"`. The tested offset-qualified start (`2026-12-16T09:00:00-06:00`) was rejected with `invalidProperties: start`. Separate `timeZone: "UTC"` with a UTC wall time also stored correctly but did NOT fix MCP readback. Never compensate by shifting a write one hour. Verify writes with CalDAV, not MCP readback alone.

For recurring appointments preserve the local time AND named timezone: weekly 09:00 remained 09:00 across fall/spring, while UTC changed correctly. Keep all-day events date-only. Resolve nonexistent spring-forward and ambiguous fall-back times with Mike before writing. Search filtering used the correct stored time in the winter test even while returned `start` was shifted; do not move search windows merely to match the bad displayed value. Alarm edits require CalDAV; inspect recurrence masters and exceptions separately and preserve relative triggers when moving an appointment.

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
