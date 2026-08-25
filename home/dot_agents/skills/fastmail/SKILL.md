---
name: fastmail
description: Read, search, organize, draft, and send Mike's Fastmail email, contacts, and calendar events via the mcporter CLI (Fastmail's official MCP server); create and edit contacts over CardDAV (scripts/carddav-contact) so Apple Contacts renders them correctly. Use whenever a task involves Mike's personal email, inbox, messages, mail folders, contacts, or personal (non-work) calendar.
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

## Contacts: Apple Contacts compatibility (use CardDAV, not the MCP contact writers)

Mike consumes his Fastmail contacts primarily through **Apple Contacts** (iOS/macOS) over CardDAV. The MCP contact *writers* produce vCards Apple mangles, so all contact writes go through `scripts/carddav-contact` instead. Verified 2026-08-25:

- `create_contact` takes `name` only as a flat string. Fastmail stores it as JSContact `name.full` with no components, so the vCard 3.0 CardDAV serves has `FN:Waldemar Dziubek` but an empty `N:;;;;`. Apple Contacts treats empty-`N` + `ORG` as a **company card**: it shows the org ("B-Stock") as the contact's name and ignores `FN` entirely.
- MCP-written `TEL` / `EMAIL` carry only a `PROP-ID=<hash>` parameter and no `TYPE=`, so Apple labels the phone field literally "PROP-ID". `ORG` is emitted under a hashed group prefix (`fec2c614085b502e.ORG;PROP-ID=…:B-Stock`).
- `update_contact` **with `name` set wipes `N` back to `;;;;`** — even on a card that was previously clean. *Without* `name` (a notes/phones/emails delta) it preserves an existing `N` and existing `TYPE=` params; it still re-serializes the card (adding `PROP-ID`s and the hashed `ORG` group), which Apple renders acceptably.
- A proper vCard 3.0 written over CardDAV fixes everything and Fastmail stores and serves it back verbatim: `N:Dziubek;Waldemar;;;`, `FN`, `ORG:B-Stock`, `TEL;TYPE=CELL,VOICE:…`, `EMAIL;TYPE=INTERNET,HOME,PREF:…`, optional `NOTE:`. MCP `search_contacts` reads CardDAV-written cards fine.

Rules:

1. **Never use MCP `create_contact`.** Create contacts with `scripts/carddav-contact new`.
2. **Never pass `name` to MCP `update_contact`.** For a name change or any structural edit: `carddav-contact get <name> > c.vcf` → edit the file → `carddav-contact put c.vcf`.
3. MCP `update_contact` for an emails / phones / notes delta is tolerable, but prefer CardDAV. **Never pass `notes: ""`** — it leaves an empty `NOTE:` property on the card; omit the field instead, or clear the note via CardDAV.
4. MCP `search_contacts` remains the right tool for reads and lookups. Its `id` values are Fastmail contact ids (e.g. `D-Ork`) and are **not** the CardDAV UID — map one to the other with `carddav-contact get <name>` (or `list`), which prints the UID. Its `name` field is derived from the JSContact name components, so it can differ from the card's `FN`.

### `scripts/carddav-contact`

Credentials come from a login-keychain generic password with service name `fastmail-carddav`: account = the Fastmail login email, password = a Fastmail **app password with Contacts (CardDAV) access** (Fastmail → Settings → Privacy & Security → Integrations → New app password). The mcporter OAuth token is scoped to the MCP server only — it 401s on CardDAV and JMAP, and must never be reused here.

```bash
security add-generic-password -s fastmail-carddav -a mike@greiling.me -w '<app-password>'
```

`FASTMAIL_CARDDAV_USER` / `FASTMAIL_CARDDAV_PASS` override the keychain for a one-off run. Endpoint: `https://carddav.fastmail.com/dav/addressbooks/user/<login-email>/Default/` (displayname "Personal"; serves vCard 3.0 and 4.0). The resource filename is `<uid>.vcf`, i.e. the vCard's own UID.

```
carddav-contact — manage Fastmail contacts over CardDAV (Apple-Contacts-safe vCards)

USAGE
  carddav-contact list
  carddav-contact get <text|uid>
  carddav-contact new --given G --family F [options]
  carddav-contact put <file.vcf>
  carddav-contact delete <uid>
  carddav-contact --help

COMMANDS
  list              Every card in the Default address book as: UID<TAB>FN<TAB>ORG
  get <text|uid>    Raw vCard(s) whose FN, ORG or EMAIL contains <text>
                    (case-insensitive), each preceded by a "# etag: ..." line.
                    A bare UID is fetched directly by GET.
  new               Build a clean vCard 3.0 and create it (HTTP 201), then
                    print the UID and re-read the stored card.
  put <file.vcf>    Upload a hand-written vCard. The UID inside the file names
                    the resource; an existing resource is updated with If-Match,
                    a new one is created with If-None-Match: *. Prints the
                    re-read card.
  delete <uid>      DELETE the card (If-Match). DESTRUCTIVE AND IRREVERSIBLE —
                    only run it after the user has explicitly confirmed that
                    specific contact should be deleted.

OPTIONS for `new`
  --given G            Given (first) name          [required]
  --family F           Family (last) name          [required]
  --fn "Display Name"  FN override                 [default: "G F"]
  --org ORG            Organization
  --email ADDR[:TYPE]  Repeatable. TYPE default HOME; first email also gets PREF.
                       Emits EMAIL;TYPE=INTERNET,<TYPE>[,PREF]
  --phone NUM[:TYPE]   Repeatable. TYPE default CELL.
                       Emits TEL;TYPE=<TYPE>,VOICE
  --note TEXT          NOTE property

CREDENTIALS
  Read from the login keychain item with service name `fastmail-carddav`:
    security add-generic-password -s fastmail-carddav -a <login-email> -w '<app-password>'
  The password must be a Fastmail *app password* with Contacts (CardDAV) access
  (Fastmail Settings -> Privacy & Security -> Integrations -> New app password).
  The mcporter OAuth token is scoped to the MCP server only and will 401 here.
  Override with env FASTMAIL_CARDDAV_USER / FASTMAIL_CARDDAV_PASS.

ENDPOINT
  https://carddav.fastmail.com/dav/addressbooks/user/<login-email>/Default/

EXAMPLES
  carddav-contact list
  carddav-contact get "Waldemar"
  carddav-contact new --given Jane --family Doe --org B-Stock \
      --email jane@example.com --phone 555-123-4567:CELL --note "Met at KubeCon"
  carddav-contact get 0d1c...-uuid > jane.vcf && $EDITOR jane.vcf && carddav-contact put jane.vcf
```

If you ever hand-roll curl against this endpoint instead: use `Depth: 1` on the `addressbook-query` REPORT, request `<card:address-data content-type="text/vcard" version="3.0"/>`, `PUT` with `Content-Type: text/vcard; charset=utf-8` plus `If-None-Match: *` (create → 201) or `If-Match: "<etag>"` (update → 204), and use CRLF line endings in the vCard. Do it from **bash**, not zsh — zsh does not word-split `${var:+-H "..."}`, so header arguments must be built as an array.

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
