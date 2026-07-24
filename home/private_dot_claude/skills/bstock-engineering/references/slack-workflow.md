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

Standard markdown converts correctly: bold/italic/strikethrough, inline code, fenced code blocks, blockquotes (nested styling works), `[text](url)` links (render as clickable links but produce NO preview card — see the permalinks/previews section), numbered and bulleted lists. Two caveats:

- **No language hints on fenced code blocks** — ` ```js ` leaks a literal "js" as the block's first line. Use bare ` ``` `.
- Bare mention keywords and `@names` are always sent as plain text — they never become live mentions (confirmed via raw read-back). Use the token syntax from the mention-keywords section when a real ping is intended and approved.
- **Never nest a blockquote inside a numbered/bulleted list** (observed 2026-07-23 in a draft): the converter absorbs everything after the quote — follow-up lines AND the remaining list items — into the quote block. Keep lists flat and place any `>` blockquote as its own top-level paragraph after the list (e.g. "placeholder quoted below" in the item, quote afterwards).
- **Ordered lists in DRAFTS fall back to plain text when items are long/formatting-heavy** (bisected 2026-07-23): sends ALWAYS tokenize `1.`/`2.` markdown into a real `rich_text_list(ordered)` (verified via raw blocks, content-independent). Drafts tokenize SHORT items fine, but a ~700-char first item dense with bold/backticks/parens made the draft store literal `1.` text lines — reproduced identically in `im` and `mpdm` channels, so channel type is ruled out; it's the draft converter degrading on item content (exact toxin not isolated: length vs token mix). Practical rule: whenever a draft contains a numbered list with substantial items, tell Mike to eyeball the composer and re-apply list formatting if the numbers are plain text — or keep list items short and put the heavy prose in paragraphs outside the list. Bulleted (`-`) lists in drafts are untested.

## Raw Web API fallback (for capabilities the MCP omits)

The Slack MCP tools don't cover everything. The plugin's user OAuth token can drive the **public Slack Web API directly** for gaps like listing/deleting scheduled messages and deleting Mike's own messages. Verified working 2026-07-22.

- **Token location**: macOS Keychain, service `Claude Code-credentials`, account `mike` — a JSON blob; the Slack entry is `mcpOAuth["plugin:slack:slack|<hash>"].accessToken` (an `xoxe.` rotating user token). Extract in-process; **never echo the token to output or logs**:
  ```bash
  CRED=$(security find-generic-password -s "Claude Code-credentials" -a "mike" -w)
  TOKEN=$(echo "$CRED" | python3 -c "import sys,json;d=json.load(sys.stdin);[print(v['accessToken']) for k,v in d['mcpOAuth'].items() if k.startswith('plugin:slack')]")
  curl -s -H "Authorization: Bearer $TOKEN" "https://slack.com/api/auth.test"
  ```
  The token rotates — always re-read it from the keychain; never cache it. Reading it triggers a one-time macOS keychain prompt Mike must allow.
- **Granted scopes** (define what's callable): `chat:write` (send/delete own messages + manage scheduled), `channels/groups/im/mpim:history`, `groups/im/mpim:write` (private-surface writes incl. mark-read), `*:read`, `search:read.*`, `reactions:write`, `canvases:write`, `users:read.email`. **Not granted**: `users.profile:write` (status-setting impossible), `channels:write` (so no mark-read on PUBLIC channels), `files:write` (no file/image uploads — `files:read` only), and `links:write` (no custom `chat.unfurl` content).
- **Verified raw-API wins over the MCP**:
  - `chat.scheduledMessages.list` — **read pending scheduled messages** (MCP can't).
  - `chat.deleteScheduledMessage` — **deschedule** before send (MCP can't). Full schedule→list→delete loop confirmed.
  - `chat.delete` — **delete Mike's own messages** (MCP can't). (Available per scope; use only on explicit instruction — it's a real send/delete action, confirmation required.)
  - `chat.update` — **edit an already-sent message in place** (MCP can't) — preserves the message's `app_id` (guard still recognizes it) and reactions/thread replies, and Slack shows an "edited" marker. Better than delete+repost for fixing/updating a posted reminder. Verified 2026-07-22.
  - `conversations.mark` — **mark READ**, but only on DMs/group-DMs/private channels (`im/mpim/groups:write`); PUBLIC channels fail `missing_scope`. Verified 2026-07-22.
  - `chat.getPermalink` — **generate the canonical permalink** for any visible message, byte-identical to the GUI "Copy link" (MCP has no permalink tool, though `slack_send_message` does return a `message_link` for its own sends). Read-only. Verified 2026-07-23.
  - `chat.postMessage` with `"unfurl_links":true` — **force a link-preview card** on a send (API sends never unfurl by default), and `chat.update` with `"attachments":[]` — **strip a preview** after the fact. Verified 2026-07-23; details in the permalinks/previews section below.
- **Still impossible** even via raw API with this token: setting Slack status/presence (scope not granted); **mark-UNREAD** (`conversations.markUnread` → `not_allowed_token_type`, a client-only op); mark-READ on public channels (`channels:write` not granted); reading/updating/deleting **drafts** (Slack internal client API, not public Web API — no token reaches it).
- **This is a fallback, not the default.** Prefer the MCP tools for anything they cover (they keep responses lean and need no token handling). Drop to raw `curl` only for a verified gap, and treat every write (delete/deschedule) under the same confirmation rules as MCP sends.

**Conversation model & capability boundaries (verified 2026-07-23):** All conversations share ONE ID namespace addressed through the `conversations.*` methods; the letter prefix does NOT reliably encode type (public AND private channels are both `C`-prefixed here; DMs are `D`, group DMs `G`). Read the real type from `conversations.info` flags: `is_channel`/`is_private`/`is_im`/`is_mpim`, plus `is_shared`+`is_ext_shared` for **Slack Connect** channels (`#bstock-campfire`, `#campfire-dom` are externally shared with the Campfire org — which is why scheduling refuses them). Two clean tiers of reachability:

- **Content + shared metadata** (messages, reactions, membership, topic, purpose, channel type, read cursor `last_read`) — standard OAuth scopes. Readable broadly for channels (not DM info — `im:read` not granted). Writable only where the *type's* write scope was granted: **`conversations.mark` (mark-read), `setTopic`, `setPurpose`, `rename` work on private channels/DMs/group DMs (`groups/im/mpim:write`) but FAIL on public channels (`channels:write` not granted)**. This is exactly why mark-read succeeds on `#bstock-campfire` but returns `missing_scope` on `#fe-guild` — it's the channel *type's* scope, not a public/private concept. Converting public↔private needs `admin.conversations.*` (Enterprise admin) — not granted.
- **Personal UI/preference state** (drafts, saved/starred, muted, sidebar sections, "VIP") — Slack **internal client API**, the same wall drafts hit. Unreachable by ANY OAuth token, **read OR write**: `stars.list`→`missing_scope`, `saved.list`→`not_allowed_token_type`, `users.prefs.get` (mute)→`missing_scope`, `users.channelSections.list`→`not_allowed_token_type`; no public "VIP" API exists. Do not attempt to automate these — direct Mike to his Slack client.

### Summarize-then-mark-read workflow

When Mike asks to summarize unread posts/channels (to clear seldom-read channels from bold/unread), after delivering the summary:

1. **Offer to mark-read the channels Claude CAN** — private channels, DMs, and group DMs, via `slack-api.sh mark-read <ch>` (omit ts to mark all read; it prints a clear "mark this one yourself" message on public channels). Marking read is Mike's own read-cursor on his own client; still offer rather than doing it silently, since it clears unread state.
2. **List the channels Mike must mark read HIMSELF** — every **public** channel in the batch, because `channels:write` is not granted so `conversations.mark` fails there. Give him the explicit list so there's no guesswork about which ones still need a manual click.

Claude can always *read* the `last_read` cursor on channels, so it can report exactly what's unread in a public channel even where it can't clear it.

**Possible future unblock (`channels:write`):** the public-channel mark-read gap (and public-channel `setTopic`/`rename`) exists only because the Claude Slack app wasn't granted `channels:write`. Mike could petition the workspace Slack admin to add that scope to the app if this becomes a recurring pain point — parked as a "maybe someday", not worth pursuing preemptively; if petitioning, bundle `files:write` (image/file uploads) into the same ask. Revisit if summarize-then-mark-read on public channels becomes a frequent ask.

**Helper script — `scripts/slack-api.sh`** (bundled with this skill) wraps the verified gaps so you don't hand-roll curl. Reads the keychain token per call (never prints it); accepts a `U…` user id OR a `D…`/`C…` channel id anywhere (auto-resolves user→DM via `conversations.open`, matching MCP ergonomics). Subcommands:

| Command | Fills MCP gap |
|---------|---------------|
| `slack-api.sh whoami` | sanity/auth check |
| `slack-api.sh scheduled-list <ch>` | **read** pending scheduled messages |
| `slack-api.sh scheduled-delete <ch> <smid>` | **deschedule** |
| `slack-api.sh scheduled-reschedule <ch> <smid> <unix_ts>` | **reschedule** (delete+recreate, preserves text — Slack has no in-place update; safe/verifiable because scheduled msgs have stable ids + a list endpoint) |
| `slack-api.sh msg-delete [--force] <ch> <ts>` | **delete a message** — AUTHORSHIP-GUARDED (see below) |
| `slack-api.sh msg-edit [--force] <ch> <ts> <new_text>` | **edit a sent message in place** — same AUTHORSHIP GUARD as msg-delete |
| `slack-api.sh mark-read <ch> [<ts>]` | **mark read** (omit ts = all); works on private/DM/group only — prints a "do it yourself" message on public channels |
| `slack-api.sh permalink <ch> <ts>` | **canonical share link** for a message (= GUI "Copy link"; thread-aware) — for decision audit trails |
| `slack-api.sh preview-strip [--force] <ch> <ts>` | **remove a link-preview card** from a sent message — AUTHORSHIP-GUARDED like msg-edit |
| `slack-api.sh react-add / react-remove <ch> <ts> <emoji>` | **remove** a reaction (MCP only adds); enables the eyes→check→remove-eyes review flow |
| `slack-api.sh open-conversation <uid[,uid,...]>` | **create-if-not-exists** a DM/group DM (prints channel id); step 1 of drafting to a never-messaged combo |

No `drafts-*` or `status-*` subcommands exist and none can be added — drafts are the internal client API, status needs an ungranted scope. Reaction emoji names take NO colons (`white_check_mark`, `eyes`, `thankyou`). Every write is real and visible → confirmation rules apply (reactions may follow an instructed task; deletes/deschedules/sends need explicit go-ahead).

**msg-delete authorship guard**: `msg-delete` fetches the target message first and **refuses unless it was sent via Claude** — the discriminator is the message's Slack `app_id == A08SF47R6P4` (the Claude app; a Mike-typed client message has NO `app_id`). Also readable as the `Sent using <@U0AJR340H60>` context block. `--force` overrides for a deliberate delete of a non-Claude message. This is a **guard-rail, not a security boundary**: the token can call `chat.delete` on anything Mike authored, so a determined/rogue agent could bypass it — the value is making the frictionless, skill-blessed path (this script) the safe-by-default one, so an agent following the documented pattern won't blanket-delete Mike's real messages. Always prefer this script over hand-rolled `chat.delete`.

### Drafting to a user or group not messaged before (verified 2026-07-23, with caveats)

Message identity note: a message is addressed by **`channel` + `ts`** (its timestamp, `sec.microsec`) — there is no separate message UUID for targeting (the `client_msg_id` on client-typed messages is dedup-only and absent on API sends). Every message op takes that pair.

To draft to a set of people who may or may not already have a group chat, treat it as **`mkdir -p` then draft** — two steps, because drafts can't be created by the raw API (internal client API), only by the `slack_send_message_draft` MCP tool:

1. `slack-api.sh open-conversation <uid[,uid,...]>` → creates-or-resolves the DM (1 user) / **MPIM group DM** (2+ users) and prints its channel id. Idempotent: the same member set always resolves to the same channel (`conversations.open` is keyed on membership), so this is safe to run whether or not the combo has been used before.
2. `slack_send_message_draft` (MCP tool) with that channel id → attach the draft. Then hand off (`open` the channel link) for Mike to review and send.

**What we know vs. what we're hedging:**

- **Group DMs (MPIMs) are `C`-prefixed** (tell them apart via `is_mpim`), auto-named `mpdm-<members>-1`, and **persist forever** — every combo ever opened stays as an empty channel (Mike already has 100+). They **cannot be deleted** via API (same wall as drafts) — only **closed** (`conversations.close` = hide from *your* sidebar, a per-viewer state; you remain a member, the channel survives). So this workflow litters a permanent empty MPIM each time a genuinely new combo is used — acceptable, but note it.
- **`is_open` is a per-viewer sidebar state**, not universal. It flips when *you* open/close a conversation AND when your client *views* it. There is **no API sequence that reproduces the GUI's "recipient-based draft with no visible channel"**: `open→draft→close` clobbers the draft (close deletes it); `open→close→draft` attaches the draft but the channel re-opens the moment you view the draft to act on it. That deferred-creation ergonomic lives only in the GUI's internal drafts API, which the token can't reach — so **via this workflow the group WILL appear in Mike's own sidebar.**
- **Visibility to OTHER members — HEDGED, not proven.** We are *reasonably confident* (documented Slack behavior: MPIMs surface to other members on the first *delivered message*, and the `is_open` we can toggle is only Mike's own) that opening/drafting to a new group does **not** make it appear in Fred/Sarah/Joe's sidebars, and **no message or notification is sent by opening or drafting**. But this is **NOT API-verifiable** — `conversations.info` only ever reports the caller's own view. Do not state it as a guarantee. **⏳ Open question to confirm later:** ask a participant (e.g. Joe Ellis) whether a never-messaged group appears for them before the first send. Until then, hedge the claim in anything user-facing, and if zero-visibility-to-others is ever a hard requirement, use the GUI's native group draft instead (it truly defers channel creation).

### Permalinks, link previews & images (verified 2026-07-23)

**Permalinks — the decision-audit-trail tool.** `slack-api.sh permalink <ch> <ts>` (wraps `chat.getPermalink`) returns the canonical share link, byte-identical to the GUI's "Copy link": top-level messages are `https://bstocksolutions.slack.com/archives/<CH>/p<ts-without-the-dot>` (so the URL is mechanically derivable from channel+ts, but use the API — it's authoritative); thread replies automatically gain `?thread_ts=<parent>&cid=<ch>`. Works on any message the token can see, including group DMs. The MCP's `slack_send_message` also returns a `message_link` permalink for each send — capture it when the send is part of a paper trail. **Primary use-case: recording where a decision came from** — e.g. Fred confirms a product decision in a group chat → `permalink` → paste into the Jira ticket. Caveat for that flow: a permalink into a **DM/group DM/private channel only resolves for its members** — most Jira readers will get "channel not found" — so when citing a private-surface decision in a ticket, quote the relevant text alongside the link rather than letting the link carry the meaning alone.

**Link previews (unfurls):**

- **API sends produce NO preview card by default** — verified for raw `chat.postMessage` AND MCP `slack_send_message` (the MCP exposes no unfurl knob at all). This is the opposite of the GUI composer, which eagerly attaches previews. So the usual worry is inverted: programmatic sends are clean by default, and no "dismiss the preview" step exists or is needed.
- **To force a preview on**, send via raw API with `"unfurl_links":true,"unfurl_media":true` — verified (Wikipedia link grew its card). The card lands **asynchronously** (~2–20 s after send) as `attachments` on the message, so verify by reading the message back, not from the send response. Domain caveat: some domains never unfurl generically — github.com produced no card even when forced (GitHub-link previews belong to the GitHub Slack integration, which isn't in play here); GitLab-internal links are untested.
- **To remove a preview from a sent message** (the GUI "x" equivalent): `slack-api.sh preview-strip <ch> <ts>` — `chat.update` with the message's own text and `"attachments":[]`, verified to strip the card and leave text/reactions intact. Authorship-guarded like `msg-edit` (Claude-authored only; `--force` to override) — for Mike's own hand-typed messages the GUI "x" is the natural tool.
- **Drafts**: preview generation happens in Mike's composer when he reviews the draft in the GUI, and he can dismiss it there before sending — preview control on drafts stays with him; nothing to manage via API.

**Images / file attachments: not possible with the current token.** The MCP has no upload tool (`slack_read_file` is read-only) and the raw API path (`files.getUploadURLExternal` → `files.completeUploadExternal`) needs `files:write`, which is not granted. Drafts can't carry attachments via API either (that's the internal client API again). Workflow: Claude drafts the text, Mike attaches the image in the composer before sending. Untested alternative: a message linking an externally-hosted image with `unfurl_media:true` *may* render it inline — probe before relying on it. If uploads become a real need, `files:write` belongs in the same admin scope petition as `channels:write` (see below).

## Key Channels

| Channel | ID | Type | Purpose |
|---------|-----|------|---------|
| `#fe-guild` | `C04225G5QCS` | public | All frontend engineers. ~99% of posts solicit review of GitLab MRs. Post here to request FE review when an MR is ready-for-review. |
| `#foundation-pod` | `C09G5BQDEJD` | public | Mike's cross-functional pod (FE + BE engineers, managers, PMs, possibly UX). Corresponds to Jira `FP` project. Team-specific posts and pod-scoped review requests. |
| `#bstock-campfire` | `C09V4EF0F3J` | private | Team ↔ Campfire Analytics (external contractor managing GTM, user-tracking telemetry, marketing analytics). Mike is the engineering liaison for most of these efforts. |
| `#tech-availability` | `C01BMD7UN1H` | public | Post when stepping away from the computer — appointments, urgent interruptions, short absences — so people know you're unavailable. |

### Review-request workflow

When an MR reaches ready-for-review (pipeline green, AI review cleared), a short post to `#fe-guild` (FE-wide) or `#foundation-pod` (pod-scoped) with the MR link solicits a human reviewer. Offer to draft this when an MR reaches that state; don't post it unprompted — but Mike HAS said (2026-07-23) that direct sends with the "Sent using @Claude" footer are fine for this message type once he gives the word for a given post.

**House format** (from Mike's #fe-guild history — mirror it):
- Casual lowercase opener naming the repo + one clause on what it does: `home-portal MR for review — adds X to Y:` / `quick MR for review:` / `fe-core MR for review: updating A and addressing B:`
- The bare MR URL on its own line (no markdown label needed).
- Multiple MRs: opener like `got a few MRs for review:` then a numbered/bulleted list, each entry `repo !iid — TICKET one-line summary <link>`.
- Optional closing status line, e.g. `one human approval needed (AI reviewer already approved)`.
- No @here/@channel, no greetings, no sign-off. Context that helps a reviewer say yes (copy already signed off, screenshots in the MR) earns one parenthetical, not a paragraph.

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
| Shuai (Sarah) Xu — PM, 3MP buyer/parcel (authored the Parcel Phase 1 PRD) | `U04QHRG8Q8G` | sarah@bstock.com | `sarah` (361) | `63ed4f0f07df05aa82766c7e` |
| Frederick (Fred) Leung — UX Designer | `U0A0Y5MRHSL` | frederick.leung@bstock.com | `frederick.leung` (626) | `712020:0accc665-be14-4f4c-9914-796fffa4d0ca` |

Name disambiguation: "Paul" alone is ambiguous in Slack (Paul Angeles `U075W4W0VDX` also exists) — Mike's "Paul R." is Paul Robertson. "Joe" is ambiguous too (Joe Ellis, Joe Dube) — Mike's "Joe S." is Spandrusyszyn. "Sarah" is ambiguous in Jira (Sarah Robinson `712020:281ecc4f-…` also exists) — the parcel-PRD PM is Sarah Xu. When adding new people to this table, verify with `slack_search_users`, `glab api "users?search=<name>"`, and `lookupJiraAccountId` rather than guessing; email is the reliable join key.

## Slack Status (PTO / meetings)

Conventions: `:palm_tree:` emoji with a status like "PTO" when on vacation; similar statuses for meetings/appointments.

**Current tooling gap (as of 2026-07-22):** the official Slack MCP server exposes no tool for setting status or presence (`users.profile.set` is not surfaced). If Mike asks to set his status, say so and fall back to asking him to set it manually — and re-check the tool roster occasionally, since Slack is actively expanding the MCP server. Posting to `#tech-availability` (which *is* possible, as a normal message) covers the "I'm stepping away" use case.
