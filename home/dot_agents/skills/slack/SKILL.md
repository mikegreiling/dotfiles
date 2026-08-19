---
name: slack
description: Read, search, and send Slack messages in the B-Stock workspace via the mcporter CLI (Slack's official MCP server) — channels, threads, DMs, drafts, canvases, reactions, user lookups. Use whenever a task involves Slack and harness-native Slack MCP tools are not available (Codex, or Claude after the Slack plugin's MCP was removed).
---

# Slack (via mcporter)

Slack's official MCP server is registered as `slack` in the mcporter home registry (`~/.mcporter/mcporter.json`), authenticated as Mike (user-scoped token — every action appears as Mike). mcporter is the harness-independent integration point — never add Slack MCP configuration to any agent harness.

## Discover tools first

The tool list is not embedded here — fetch it live (includes full input schemas):

```bash
mcporter list slack --json
```

Tool names match the Slack MCP server's own (`slack_search_public`, `slack_read_channel`, `slack_send_message`, `slack_send_message_draft`, `slack_read_thread`, `slack_create_canvas`, …).

## Call a tool

```bash
mcporter call slack.<tool_name> --args '<json>' --output json --no-oauth
```

- Always pass `--no-oauth` and `--output json`. Arguments are one JSON object via `--args`.
- Exit codes are only 0/1 — branch on the JSON payload. On `issue.kind == "auth"`, see "Re-authentication" below.
- If a call reports the server requested interactive input (elicitation): mcporter auto-declines it in non-TTY contexts. Hand Mike the exact same `mcporter call` command to run in a real terminal, where mcporter prompts inline.

## Token lifecycle and refresh

The Slack token is a rotating `xoxe.` user token (~12h TTL) stored in mcporter's vault (`$XDG_DATA_HOME/mcporter/credentials.json`, falling back to `~/.mcporter/credentials.json`). mcporter refreshes it automatically during ANY connection — **including under `--no-oauth`** — redeeming the single-use refresh token under a cross-process lock and persisting the result.

- To force a refresh explicitly (e.g. before reading the raw token from the vault for direct Web API calls):

  ```bash
  mcporter list slack --no-oauth --json >/dev/null
  ```

- NEVER redeem the refresh token yourself (no direct calls to `slack.com/api/oauth.v2.user.access`) — it is single-use; racing mcporter kills the token family and forces a full re-auth.
- For raw Web API access, use `bstock-engineering`'s `scripts/slack-api.sh` `_token()` — it implements the vault read + staleness nudge correctly.

## Re-authentication (`issue.kind == "auth"`)

Default: STOP and tell Mike to run `mcporter auth slack` in a real terminal. With Mike's explicit go-ahead in the conversation, you MAY run `mcporter auth slack` yourself in the foreground with a generous timeout (≥600000ms) — it opens his browser and waits on a loopback callback. If it fails or times out, do NOT retry (repeated attempts spawn browser windows); fall back to asking Mike to run it himself.

## Client identity — pinned to the Claude Slack app (auditability note)

The registry pins `oauthClientId` to the Claude Slack app (`1601185624273.8899143856786`, app `A08SF47R6P4`) because Slack's MCP authorization server offers no dynamic client registration. Consequences, explored and accepted 2026-08-19:

- Granted scopes are capped by that app's manifest (26 scopes: read/history/search across surfaces, `chat:write`, private-surface writes, `canvases:write`, `reactions:write`). Requesting wider scopes (`files:write`, `channels:write`, `lists:*`) was tried and NOT granted.
- Creating our own Slack app (own manifest, own client ID) would lift those caps but requires B-Stock workspace-admin approval — judged a non-starter; the Claude app is already approved.
- **If auth ever starts failing with client/registration-shaped errors** (invalid_client, redirect rejection), the likely cause is Anthropic or Slack constraining that client registration. That is a known accepted risk, not a config bug. Mitigation plan: revisit the own-Slack-app route with workspace admins, or pin whatever client the then-current Claude integration uses.

## B-Stock enhancements and etiquette (IMPORTANT)

The `bstock-engineering` skill's Slack section is the authority for B-Stock Slack workflows. It provides `scripts/slack-api.sh`, which reuses the same OAuth token against raw `slack.com/api` endpoints the MCP server does not expose (scheduled messages, message edit/delete, mark-read, reactions, presence, permalinks). For anything beyond plain reading/searching/sending — scheduling, editing, deleting, meeting-facilitation workflows — load `bstock-engineering` and follow its `references/slack-workflow.md`, including its authorship-guard and message-etiquette rules (e.g. the "Sent using @Claude" footer conventions).

## Sending is outward-facing

Messages, drafts, canvases, and reactions are visible to other people immediately. Confirm with Mike before sending anything he hasn't explicitly dictated or approved; prefer `slack_send_message_draft` over `slack_send_message` when composing on his behalf.
