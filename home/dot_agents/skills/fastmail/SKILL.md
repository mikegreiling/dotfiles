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

## Error handling

Exit codes are only 0/1 — branch on the JSON payload, not `$?`. Failures print an envelope with `issue.kind`:

- `"auth"` → tokens missing or expired. Default: STOP and tell Mike to run `mcporter auth fastmail` in a real terminal. With Mike's explicit go-ahead in the conversation, you MAY run it yourself in the foreground with a generous timeout (≥600000ms) — it opens his browser and waits on a loopback callback; if it fails or times out, do NOT retry (repeated attempts spawn browser windows).
- `"offline"` / `"http"` / `"stdio-exit"` / `"other"` → connectivity or server problem; report `issue.rawMessage` to Mike.

Token refresh is automatic during any mcporter connection, including under `--no-oauth`. To force a refresh explicitly: `mcporter list fastmail --no-oauth --json >/dev/null`. Never redeem refresh tokens outside mcporter.

Registry note: the fastmail entry pins `oauthRedirectUrl` to `http://localhost:3119/callback`. Do not remove it — Fastmail normalizes registered loopback redirect URIs (strips ports), which breaks mcporter's dynamic-port registration check ("obsolete redirect URI" error).

## Interactive confirmations (MCP elicitation)

Fastmail's server can require confirmation before destructive operations (an MCP elicitation request — the "press to confirm" UI seen in MCP-native harnesses). mcporter relays these prompts only when BOTH stdin and stderr are TTYs. From an agent (non-TTY), mcporter automatically DECLINES the request and the operation does not execute. When that happens: report it and hand Mike the exact `mcporter call fastmail.<tool> --args '<json>'` command to run in a real terminal, where mcporter prompts inline. There is currently no auto-accept flag; do not try to work around the decline.

"Real terminal" means Terminal.app/iTerm — Claude Code's `!` bash-input prefix does NOT attach a TTY, so mcporter still auto-declines there (verified 2026-08-19 with `delete_event`). A declined elicitation is silent: the call exits 0 and echoes the staged event back as if it succeeded, so after any destructive call, verify the effect (e.g. `search_events`) before reporting success.

## Safety

Fastmail grants read / change / send scopes. Sending email and deleting or moving messages are real-world actions — confirm with Mike before invoking send or destructive tools unless he explicitly asked for that exact operation.
