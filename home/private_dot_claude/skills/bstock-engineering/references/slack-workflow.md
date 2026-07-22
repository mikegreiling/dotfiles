# Slack Workflow

How the team uses Slack, and how to act there on Mike's behalf via the official Slack MCP server (installed as the `slack` Claude Code plugin). All IDs and emoji names below were verified live on 2026-07-22.

## Posting on Mike's behalf — ground rules

- The MCP connection uses Mike's **user OAuth token**: messages and reactions appear **as Mike**. Messages sent via MCP carry a visible **"Sent using @Claude"** footer (verified 2026-07-22 on a scheduled send; assume all sends). Reactions show no attribution. Treat every send/react as Mike speaking, with the send footer as a transparency marker — not a substitute for confirmation.
- **Never send a message without confirming with Mike first.** Even when a task implies a post (e.g. an MR just went ready-for-review), compose it and get his explicit go-ahead — or better, leave it as a draft. No exceptions.
- **Reactions are lighter-weight**: when they follow from a task Mike instructed (e.g. he asks for work on an MR solicited in Slack → adding `:eyes:`/`:white_check_mark:` per the conventions below), no pre-confirmation needed — but **always tell Mike about every reaction added**, in the report for that task. Don't add reactions unrelated to what he asked for.
- **Drafts are exempt from confirmation**: creating a draft via `slack_send_message_draft` is always fine — Mike reviews and sends drafts himself in the Slack client. Default to drafts whenever composing anything on his behalf.

### Draft gotchas — verify after write (verified 2026-07-22)

- Slack allows only **one attached draft per channel**. Creating a draft where one already exists **silently no-ops**: the API returns success anyway, the old draft's content survives, and the new content is lost.
- The reliable signal is the **`draft_id` field in the response**: present = draft created; absent = nothing was written. Confirmed 3/3 across public channels (#fe-guild, #foundation-pod) and a self-DM. **Check it after every `slack_send_message_draft` call.** On a missing `draft_id`, tell Mike the draft did NOT land, show him the composed text inline so nothing is lost, and either let him paste it manually or have him clear/send the existing draft before retrying.
- There is **no tool to list, read, update, or delete drafts** as standalone operations. The one consumer of `draft_id` is `slack_send_message`'s optional `draft_id` param, which deletes that draft after sending. Never claim a draft exists or was updated based on a success message alone.

**Draft-ID lifecycle & the `draft_id` send param (probed exhaustively 2026-07-22):**

- A draft ID is minted when a draft object is created in a channel's empty slot, and **survives ALL editing** — including Mike cmd+A-replacing the entire contents. The ID dies only when the draft is **sent** or **deleted** (emptying the composer = deletion).
- `slack_send_message` + `draft_id` always sends the **`message` param text** (the draft's content is never the source of truth) and then deletes the draft **matching that exact ID — targeted, not channel-wide**. Unrelated drafts in the same channel are safe. A stale/dead `draft_id` silently no-ops — **no error is ever raised**, so there is no API-level guard against clobbering.
- **Consequence — the edited-draft foot-gun**: if Mike edits or even fully rewrites a Claude-created draft, its ID still matches, and a later `draft_id` send will silently destroy his version while sending Claude's param text. The ONLY safe uses of `draft_id` are: (a) Mike approves sending in chat AND confirms he hasn't touched the draft; (b) the send happens in the same exchange as the draft's creation. In any other situation, send WITHOUT `draft_id` and let Mike clear the leftover draft manually.
- **Detection trick**: since creates no-op against an occupied slot, an attempted draft-create doubles as an existence probe for the channel's slot (`draft_id` returned = slot was empty). Costs nothing when it no-ops; if it unexpectedly lands, tell Mike about the junk draft.
- **Non-idempotent retry hazard**: if a draft-create errors at the transport layer (socket drop), do not blindly retry — the sentinel on the retry response is the truth about whether anything landed.
- **Hand-off flow**: after a verified draft, run `open "<channel_link from the response>"` (macOS) — it opens the channel in Mike's Slack app with the attached draft waiting in the composer for him to review and send.
- Drafts are Slack's **internal client API** (`drafts.*`), not the public OAuth Web API — richer draft operations can't be added via any official-token tool, only via browser-session-token tools.

### Scheduled messages

`slack_schedule_message` schedules a real send (Unix timestamp ≥2 min out, ≤120 days; thread replies supported via `thread_ts`; unavailable in Slack Connect channels). **Scheduling is sending, not drafting — Mike's confirmation rule applies in full** (exact text, channel, and time). There is no tool to list, edit, or cancel a scheduled message; after scheduling, changes happen only in Mike's client under "Drafts & Sent".

### Mention keywords (@here / @channel / @everyone)

Slack has exactly three special mentions (there is no `@all`): `@here` notifies only currently-active channel members; `@channel` notifies every channel member including offline; `@everyone` notifies the whole workspace and only works in #general. Policy:

- **`@everyone`: never use. No exceptions.**
- **`@channel`: never use** unless Mike dictates it verbatim in the message text — and restate its offline-ping blast radius when confirming.
- **`@here`: allowed** when it appears in message text Mike has approved.
- To **refer** to a keyword or user group without pinging (e.g. discussing `@here` or `@bstock`), wrap it in backticks — verified: backtick-wrapped keywords render as literal code, no ping.

**Producing LIVE mentions** (verified 2026-07-22): bare `@name`/`@here` text never tokenizes through the MCP — real mentions require Slack's token syntax in the message: `<@U065SDTU138>`-style for users (server enriches to `<@U…|Name>`), `<!here>` for @here. Works in both direct sends and drafts. So a guild-meeting-style reminder with a live `@here` CAN be sent programmatically (confirmation rule applies as always). `<!channel>`/`<!everyone>` presumably work the same — they remain forbidden per the policy above.

### Message formatting via MCP (verified 2026-07-22)

Standard markdown converts correctly: bold/italic/strikethrough, inline code, fenced code blocks, blockquotes (nested styling works), `[text](url)` links (they unfurl), numbered and bulleted lists. Two caveats:

- **No language hints on fenced code blocks** — ` ```js ` leaks a literal "js" as the block's first line. Use bare ` ``` `.
- Bare mention keywords and `@names` are always sent as plain text — they never become live mentions (confirmed via raw read-back). Use the token syntax from the mention-keywords section when a real ping is intended and approved.

## Raw Web API fallback (for capabilities the MCP omits)

The Slack MCP tools don't cover everything. The plugin's user OAuth token can drive the **public Slack Web API directly** for gaps like listing/deleting scheduled messages and deleting Mike's own messages. Verified working 2026-07-22.

- **Token location**: macOS Keychain, service `Claude Code-credentials`, account `mike` — a JSON blob; the Slack entry is `mcpOAuth["plugin:slack:slack|<hash>"].accessToken` (an `xoxe.` rotating user token). Extract in-process; **never echo the token to output or logs**:
  ```bash
  CRED=$(security find-generic-password -s "Claude Code-credentials" -a "mike" -w)
  TOKEN=$(echo "$CRED" | python3 -c "import sys,json;d=json.load(sys.stdin);[print(v['accessToken']) for k,v in d['mcpOAuth'].items() if k.startswith('plugin:slack')]")
  curl -s -H "Authorization: Bearer $TOKEN" "https://slack.com/api/auth.test"
  ```
  The token rotates — always re-read it from the keychain; never cache it. Reading it triggers a one-time macOS keychain prompt Mike must allow.
- **Granted scopes** (define what's callable): `chat:write` (send/delete own messages + manage scheduled), `channels/groups/im/mpim:history`, `*:read`, `search:read.*`, `reactions:write`, `canvases:write`, `users:read.email`. **Not granted**: `users.profile:write` (so status-setting is impossible even here) and no mark-read scope.
- **Verified raw-API wins over the MCP**:
  - `chat.scheduledMessages.list` — **read pending scheduled messages** (MCP can't).
  - `chat.deleteScheduledMessage` — **deschedule** before send (MCP can't). Full schedule→list→delete loop confirmed.
  - `chat.delete` — **delete Mike's own messages** (MCP can't). (Available per scope; use only on explicit instruction — it's a real send/delete action, confirmation required.)
- **Still impossible** even via raw API with this token: setting Slack status/presence (scope not granted); reading/updating/deleting **drafts** (Slack internal client API, not public Web API — no token reaches it).
- **This is a fallback, not the default.** Prefer the MCP tools for anything they cover (they keep responses lean and need no token handling). Drop to raw `curl` only for a verified gap, and treat every write (delete/deschedule) under the same confirmation rules as MCP sends.

**Helper script — `scripts/slack-api.sh`** (bundled with this skill) wraps the verified gaps so you don't hand-roll curl. Reads the keychain token per call (never prints it); accepts a `U…` user id OR a `D…`/`C…` channel id anywhere (auto-resolves user→DM via `conversations.open`, matching MCP ergonomics). Subcommands:

| Command | Fills MCP gap |
|---------|---------------|
| `slack-api.sh whoami` | sanity/auth check |
| `slack-api.sh scheduled-list <ch>` | **read** pending scheduled messages |
| `slack-api.sh scheduled-delete <ch> <smid>` | **deschedule** |
| `slack-api.sh scheduled-reschedule <ch> <smid> <unix_ts>` | **reschedule** (delete+recreate, preserves text — Slack has no in-place update; safe/verifiable because scheduled msgs have stable ids + a list endpoint) |
| `slack-api.sh msg-delete [--force] <ch> <ts>` | **delete a message** — AUTHORSHIP-GUARDED (see below) |
| `slack-api.sh react-add / react-remove <ch> <ts> <emoji>` | **remove** a reaction (MCP only adds); enables the eyes→check→remove-eyes review flow |

No `drafts-*` or `status-*` subcommands exist and none can be added — drafts are the internal client API, status needs an ungranted scope. Reaction emoji names take NO colons (`white_check_mark`, `eyes`, `thankyou`). Every write is real and visible → confirmation rules apply (reactions may follow an instructed task; deletes/deschedules/sends need explicit go-ahead).

**msg-delete authorship guard**: `msg-delete` fetches the target message first and **refuses unless it was sent via Claude** — the discriminator is the message's Slack `app_id == A08SF47R6P4` (the Claude app; a Mike-typed client message has NO `app_id`). Also readable as the `Sent using <@U0AJR340H60>` context block. `--force` overrides for a deliberate delete of a non-Claude message. This is a **guard-rail, not a security boundary**: the token can call `chat.delete` on anything Mike authored, so a determined/rogue agent could bypass it — the value is making the frictionless, skill-blessed path (this script) the safe-by-default one, so an agent following the documented pattern won't blanket-delete Mike's real messages. Always prefer this script over hand-rolled `chat.delete`.

## Key Channels

| Channel | ID | Type | Purpose |
|---------|-----|------|---------|
| `#fe-guild` | `C04225G5QCS` | public | All frontend engineers. ~99% of posts solicit review of GitLab MRs. Post here to request FE review when an MR is ready-for-review. |
| `#foundation-pod` | `C09G5BQDEJD` | public | Mike's cross-functional pod (FE + BE engineers, managers, PMs, possibly UX). Corresponds to Jira `FP` project. Team-specific posts and pod-scoped review requests. |
| `#bstock-campfire` | `C09V4EF0F3J` | private | Team ↔ Campfire Analytics (external contractor managing GTM, user-tracking telemetry, marketing analytics). Mike is the engineering liaison for most of these efforts. |
| `#tech-availability` | `C01BMD7UN1H` | public | Post when stepping away from the computer — appointments, urgent interruptions, short absences — so people know you're unavailable. |

### Review-request workflow

When an MR reaches ready-for-review (pipeline green, AI review cleared), a short post to `#fe-guild` (FE-wide) or `#foundation-pod` (pod-scoped) with the MR link solicits a human reviewer. Typical format is minimal — e.g. "Bug fix MR for review: <MR link>". Offer to draft this when an MR reaches that state; don't post it unprompted.

## Reaction Emoji Conventions

Reactions (Slack's term; aka "reacji" — a mix of Unicode and workspace-custom emojis) carry workflow meaning, especially on review-request posts:

| Reaction | Emoji name | Meaning |
|----------|-----------|---------|
| ✅ green box w/ white check | `:white_check_mark:` | Approved |
| merged (custom) | `:merged:` | Approved **and** merged |
| eyes 👀 | `:eyes:` | "I'm looking at this" |
| thank you (custom) | `:thankyou:` | Gratitude — Mike typically adds this to a reviewer's approval/merge |

Uses:

- **Interpreting**: when checking the status of a posted review request, read its reactions — `:eyes:` = someone's on it, `:white_check_mark:` = approved, `:merged:` = done.
- **Acting** (on Mike's instruction): add `:eyes:` when Mike starts looking at something, `:white_check_mark:` when he approves, `:thankyou:` after someone approves/merges for him.
- The workspace has many near-duplicate thanks emojis (`:thank-you:`, `:thank_you:`, `:thankyou_ty:`, …) — Mike's convention is **`:thankyou:`**. Use `slack_search_emojis` to verify any other custom emoji name before reacting.

## People — Cross-System Identity Map

Common collaborators, mapped across systems (Slack/Jira verified via live lookup; GitLab via `glab api users?search=`):

| Person | Slack ID | Email | GitLab (id) | Jira accountId |
|--------|----------|-------|-------------|----------------|
| Mike Greiling | `U065SDTU138` | mike.greiling@bstock.com | `mike.greiling` (421) | `712020:102e13ca-76c4-4a0c-89e1-c9fc45369c5d` |
| Joe Spandrusyszyn ("Joe S.") | `U049J4ALL69` | joseph.spandrusyszyn@bstock.com | `joseph.spandrusyszyn` (332) | `63659c17b7b39379d722512a` |
| Paul Robertson | `U065LP1M6UX` | paul@bstock.com | `paul` (419) | `712020:b9d94b10-920e-4d35-915b-9994724c9934` |
| Alvaro Ferreira | `UPMJC0VFH` | alvaro@bstock.com | `alvarobstock` (15) | `5acbb67101a2012a6c31de20` |

Name disambiguation: "Paul" alone is ambiguous in Slack (Paul Angeles `U075W4W0VDX` also exists) — Mike's "Paul R." is Paul Robertson. "Joe" is ambiguous too (Joe Ellis, Joe Dube) — Mike's "Joe S." is Spandrusyszyn. When adding new people to this table, verify with `slack_search_users`, `glab api "users?search=<name>"`, and `lookupJiraAccountId` rather than guessing; email is the reliable join key.

## Slack Status (PTO / meetings)

Conventions: `:palm_tree:` emoji with a status like "PTO" when on vacation; similar statuses for meetings/appointments.

**Current tooling gap (as of 2026-07-22):** the official Slack MCP server exposes no tool for setting status or presence (`users.profile.set` is not surfaced). If Mike asks to set his status, say so and fall back to asking him to set it manually — and re-check the tool roster occasionally, since Slack is actively expanding the MCP server. Posting to `#tech-availability` (which *is* possible, as a normal message) covers the "I'm stepping away" use case.
