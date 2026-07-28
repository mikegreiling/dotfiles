# Slack Workflow

How the team uses Slack, and how to act there on Mike's behalf via the official Slack MCP server (installed as the `slack` Claude Code plugin). All IDs and emoji names below were verified live on 2026-07-22.

## Posting on Mike's behalf — ground rules

- The MCP connection uses Mike's **user OAuth token**: messages and reactions appear **as Mike**. Messages sent via MCP carry a visible **"Sent using @Claude"** footer (verified 2026-07-22 on a scheduled send; assume all sends). Reactions show no attribution. Treat every send/react as Mike speaking, with the send footer as a transparency marker — not a substitute for confirmation.
- **Never send a message without confirming with Mike first.** Even when a task implies a post (e.g. an MR just went ready-for-review), compose it and get his explicit go-ahead — or better, leave it as a draft. No exceptions.
- **Reactions are lighter-weight**: when they follow from a task Mike instructed (e.g. he asks for work on an MR solicited in Slack → adding `:eyes:`/`:white_check_mark:` per the conventions below), no pre-confirmation needed — but **always tell Mike about every reaction added**, in the report for that task. Don't add reactions unrelated to what he asked for.
- **Drafts are exempt from confirmation**: creating a draft via `slack_send_message_draft` is always fine — Mike reviews and sends drafts himself in the Slack client. Default to drafts whenever composing anything on his behalf.

### Voice: don't sound like an AI (per Mike, 2026-07-27)

Messages drafted for Mike should read as if he typed them; it should not be obvious Claude composed them.

- **Em dashes: very sparingly.** Not strictly forbidden, but they are the loudest AI tell. Prefer semicolons, commas, regular hyphens, parentheses, or splitting into two sentences. One em dash in a long message is fine; several is a giveaway.
- Avoid other AI-isms: "Not X — Y" contrast constructions, triadic flourishes ("clear, concise, and correct"), bolded lead-in labels on every bullet, "Here's the thing:", "worth noting", "to be clear", excessive hedging, and tidy section-header structure in what should be a casual message.
- Match Mike's actual register, which is visible in any DM history: lowercase informal openers, short direct sentences, light punctuation, minimal formatting in DMs, emoji rarely and only where natural. Channel posts (e.g. #fe-guild review asks) are terse link lists, not prose.
- Before creating a draft, reread it once specifically hunting for these tells and rewrite them out.

### Always link the things you reference (per Mike, 2026-07-27)

Whenever a message mentions a specific referenceable artifact, embed the direct link rather than a bare identifier the reader has to go look up:

- **Jira tickets**: make the ticket ID itself clickable — markdown `[FP-1234](https://bstock.atlassian.net/browse/FP-1234)` (the MCP converts markdown links to Slack link tokens in both sends and drafts).
- **Merge requests**: link the MR — `[seller-portal !2095](https://gitlab.bstock.io/b-stock/code/three-mp/fe/seller-portal/-/merge_requests/2095)`.
- **GitLab jobs/pipelines**: link the specific job (`.../-/jobs/<id>`) or pipeline (`.../-/pipelines/<id>`), not just its numeric ID.
- Same idea for anything else with a canonical URL (Confluence pages, dashboards, commits).

Resolve real URLs (via glab/acli/known URL patterns); never guess a link. Bare IDs are acceptable only when no canonical URL exists.

### Draft gotchas — verify after write (verified 2026-07-22)

- **Thread replies can be drafted** (verified 2026-07-24): pass `thread_ts` to `slack_send_message_draft` and the draft attaches to that thread's composer — so "draft a response to this threaded message" works everywhere drafting works.
- Draft slots are **per-composer, not per-channel**: the channel composer and each thread composer each hold at most ONE attached draft, and they coexist independently (channel draft + thread draft side-by-side in one conversation confirmed). Creating a draft where that composer's slot is already occupied **silently no-ops**: the API answers "Draft message is created" anyway, the old draft's content survives, and the new content is lost — verified for channel composers (2026-07-22) AND thread composers (2026-07-24).
- The reliable signal is the **`draft_id` field in the response**: present = draft created; absent = nothing was written. Confirmed across public channels (#fe-guild, #foundation-pod), a self-DM, and a thread composer. **Check it after every `slack_send_message_draft` call.** On a missing `draft_id`, tell Mike the draft did NOT land, show him the composed text inline so nothing is lost, and either let him paste it manually or have him clear/send the existing draft before retrying.
- There is **no tool to list, read, update, or delete drafts** as standalone operations. The one consumer of `draft_id` is `slack_send_message`'s optional `draft_id` param, which deletes that draft after sending. Never claim a draft exists or was updated based on a success message alone.

**Draft-ID lifecycle & the `draft_id` send param (probed exhaustively 2026-07-22):**

- A draft ID is minted when a draft object is created in a channel's empty slot, and **survives ALL editing** — including Mike cmd+A-replacing the entire contents. The ID dies only when the draft is **sent** or **deleted** (emptying the composer = deletion).
- `slack_send_message` + `draft_id` always sends the **`message` param text** (the draft's content is never the source of truth) and then deletes the draft **matching that exact ID — targeted, not channel-wide**. Unrelated drafts in the same channel are safe. A stale/dead `draft_id` silently no-ops — **no error is ever raised**, so there is no API-level guard against clobbering.
- **Consequence — the edited-draft foot-gun**: if Mike edits or even fully rewrites a Claude-created draft, its ID still matches, and a later `draft_id` send will silently destroy his version while sending Claude's param text. The ONLY safe uses of `draft_id` are: (a) Mike approves sending in chat AND confirms he hasn't touched the draft; (b) the send happens in the same exchange as the draft's creation. In any other situation, send WITHOUT `draft_id` and let Mike clear the leftover draft manually.
- **Detection trick**: since creates no-op against an occupied slot, an attempted draft-create doubles as an existence probe for that composer's slot — channel or thread (`draft_id` returned = slot was empty). Costs nothing when it no-ops; if it unexpectedly lands, tell Mike about the junk draft.
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
  - `conversations.create` with `"is_private":true` + `conversations.archive` — **create and archive PRIVATE channels** (`groups:write`; verified 2026-07-24). Public-channel creation is not granted. `conversations.invite` is untested — it notifies invitees, so treat it like a send (confirm first). Note: non-admins cannot truly DELETE a channel — archive is the end state.
  - `canvases.create` / `canvases.delete` — **full canvas lifecycle** (verified 2026-07-24; the MCP covers create/read/update, raw adds delete). The one "share substantial rich content" capability we have, given file uploads are impossible.
  - `users.getPresence` + the `status_*`/`huddle_state` fields on `users.info` — **read anyone's presence, status, and huddle state** (raw `users.profile.get` is `missing_scope`, but `users.info` carries the same status fields). Wrapped as `slack-api.sh status <uid>`.
  - **Confirmed walls (all `missing_scope`, swept 2026-07-24)**: pins, channel bookmarks, reminders, user groups (`usergroups.list` — so `@fe-guild`-style subteam mentions can't be *resolved*; a live `<!subteam^ID>` token could still be hand-built from an ID observed in message history), DND info, and Slack Lists.
- **Still impossible** even via raw API with this token: setting Slack status/presence (scope not granted); **mark-UNREAD** (`conversations.markUnread` → `not_allowed_token_type`, a client-only op); mark-READ on public channels (`channels:write` not granted); reading/updating/deleting **drafts** (Slack internal client API, not public Web API — no token reaches it).
- **This is a fallback, not the default.** Prefer the MCP tools for anything they cover (they keep responses lean and need no token handling). Drop to raw `curl` only for a verified gap, and treat every write (delete/deschedule) under the same confirmation rules as MCP sends.

**Conversation model & capability boundaries (verified 2026-07-23):** All conversations share ONE ID namespace addressed through the `conversations.*` methods; the letter prefix does NOT reliably encode type (public AND private channels are both `C`-prefixed here; DMs are `D`, group DMs `G`). Read the real type from `conversations.info` flags: `is_channel`/`is_private`/`is_im`/`is_mpim`, plus `is_shared`+`is_ext_shared` for **Slack Connect** channels (`#bstock-campfire`, `#campfire-dom` are externally shared with the Campfire org — which is why scheduling refuses them). Two clean tiers of reachability:

- **Content + shared metadata** (messages, reactions, membership, topic, purpose, channel type, read cursor `last_read`) — standard OAuth scopes. Readable broadly for channels (not DM info — `im:read` not granted). Writable only where the *type's* write scope was granted: **`conversations.mark` (mark-read), `setTopic`, `setPurpose`, `rename` work on private channels/DMs/group DMs (`groups/im/mpim:write`) but FAIL on public channels (`channels:write` not granted)**. This is exactly why mark-read succeeds on `#bstock-campfire` but returns `missing_scope` on `#fe-guild` — it's the channel *type's* scope, not a public/private concept. Converting public↔private needs `admin.conversations.*` (Enterprise admin) — not granted.
- **Personal UI/preference state** (drafts, saved/starred, muted, sidebar sections, "VIP") — Slack **internal client API**, the same wall drafts hit. Unreachable by ANY OAuth token, **read OR write**: `stars.list`→`missing_scope`, `saved.list`→`not_allowed_token_type`, `users.prefs.get` (mute)→`missing_scope`, `users.channelSections.list`→`not_allowed_token_type`; no public "VIP" API exists. Do not attempt to automate these — direct Mike to his Slack client.

### Correspondence & topic watches — sync-since-cursor (verified 2026-07-24)

The canonical recipe for "catch me up on everything between me and persons X, Y (and project channel #Z) since T" — the common project-coordination ask. Search is the discovery primitive; **never enumerate conversations**.

- Keep a **cursor**: the Unix ts of the last successful sync, stored wherever the watching session/project keeps state. Every search below passes it via the MCP search tools' **`after` parameter, which takes an exact Unix timestamp** (the in-query `after:YYYY-MM-DD` modifier is only day-granular — don't use it for cursors). After a sync, advance the cursor to the sync *time*, not the max hit ts — a silent interval must advance it too.
- **Two-way private correspondence, one call per person**: `with:<@UID>` scoped with `channel_types=im,mpim` returns every message in every DM **and group DM whose membership includes that person — any author, including Mike's own replies**. This is the trick that avoids enumerating MPIMs and answers "what did *I* tell them" in the same pass. ⚠️ Unscoped `with:` means "conversations where UID is a *member*", so on public channels it returns the entire channel's unrelated traffic — always scope it to `im,mpim`.
- **Their posts anywhere**: `from:<@UID>` (all channel types) catches the "they posted it in some channel without mentioning us" case. Overlaps the `with:` results — dedupe hits by channel+ts.
- **The known project channel**: `in:#channel` (any author) covers chatter there, including Mike's.
- Slack search is AND-only (no OR), so it's **one query per person/channel/topic term: O(people + channels + topics) search calls per sync — independent of how many hundreds of conversations Mike is in**. Result volume scales only with actual new correspondence (20 hits/page, cursor pagination; raw `search.messages` does 100/page if ever needed). The naive alternative — enumerate all MPIMs containing X, read each — is O(all conversations) of mostly-empty reads; never do it.
- **Thread replies are indexed as first-class search hits**, so threaded responses surface without thread-walking. Use `slack_read_thread`/`slack_read_channel` only to pull surrounding context for hits that matter.
- **Topic watches** (a Jira ticket, an epic, a feature name): query the literal key — `"FP-2560" after=<cursor>` — ticket IDs are ideal exact search tokens. Caveat: **search excludes bot messages by default**; pass `include_bots=true` when Jira/GitLab integration chatter about the ticket counts as signal.
- Inherent blind spot: the search index covers only conversations **Mike is a member of** — X's posts in channels he isn't in never appear, under any token of his.

### Summarize-then-mark-read workflow

When Mike asks to summarize unread posts/channels (to clear seldom-read channels from bold/unread), after delivering the summary:

1. **Offer to mark-read the channels Claude CAN** — private channels, DMs, and group DMs, via `slack-api.sh mark-read <ch>` (omit ts to mark all read; it prints a clear "mark this one yourself" message on public channels). Marking read is Mike's own read-cursor on his own client; still offer rather than doing it silently, since it clears unread state.
2. **List the channels Mike must mark read HIMSELF** — every **public** channel in the batch, because `channels:write` is not granted so `conversations.mark` fails there. Give him the explicit list so there's no guesswork about which ones still need a manual click.

Claude can always *read* the `last_read` cursor on channels, so it can report exactly what's unread in a public channel even where it can't clear it.

**Possible future unblocks for `missing_scope` walls (mechanism verified 2026-07-25):** every `missing_scope` failure in this doc is a limitation of the **Claude app's OAuth token, not of Mike's account** — Slack tokens carry exactly the scopes the app requested at authorization, and account/workspace-policy limits surface as different errors (`restricted_action`-style), which we have never hit. Mike's own account pins, reminds, uploads, and creates channels fine in the GUI; only the token is narrower. Consequently a workspace admin **cannot** fix this — admins approve/restrict third-party apps but cannot add scopes to Anthropic's app manifest. The two real unlock paths, both parked as Someday tasks in Things: (1) **Anthropic broadens the Claude app's scopes** — after plugin/server updates, re-run the scope check (`auth.test` + the `x-oauth-scopes` response header) and diff against the granted-scopes list above; (2) **a personal Slack app** requesting exactly the missing scopes (`files:write`, `channels:write`, pins/bookmarks/reminders/usergroups/DND), installed subject to workspace app-approval policy, whose token `slack-api.sh` could use as a secondary credential. Neither path helps with internal-client-API walls (drafts CRUD, mark-unread, stars/mute/sections, Threads badge) — those are closed to every OAuth token.

**Helper script — `scripts/slack-api.sh`** (bundled with this skill) wraps the verified gaps so you don't hand-roll curl. Reads the keychain token per call (never prints it); accepts a `U…` user id OR a `D…`/`C…` channel id anywhere (auto-resolves user→DM via `conversations.open`, matching MCP ergonomics). Subcommands:

| Command | Fills MCP gap |
|---------|---------------|
| `slack-api.sh whoami` | sanity/auth check |
| `slack-api.sh scheduled-list <ch>` | **read** pending scheduled messages |
| `slack-api.sh scheduled-delete <ch> <smid>` | **deschedule** |
| `slack-api.sh scheduled-reschedule <ch> <smid> <unix_ts> [<thread_ts>]` | **reschedule** (delete+recreate, preserves text — Slack has no in-place update; safe/verifiable because scheduled msgs have stable ids + a list endpoint). If the scheduled message was a **thread reply**, pass the parent ts as the 4th arg — the script can't detect threading itself (see its comments) |
| `slack-api.sh msg-delete [--force] <ch> <ts>` | **delete a message** — AUTHORSHIP-GUARDED (see below) |
| `slack-api.sh msg-edit [--force] <ch> <ts> <new_text>` | **edit a sent message in place** — same AUTHORSHIP GUARD as msg-delete |
| `slack-api.sh mark-read <ch> [<ts>]` | **mark read** (omit ts = all); works on private/DM/group only — prints a "do it yourself" message on public channels |
| `slack-api.sh permalink <ch> <ts>` | **canonical share link** for a message (= GUI "Copy link"; thread-aware) — for decision audit trails |
| `slack-api.sh preview-strip [--force] <ch> <ts>` | **remove a link-preview card** from a sent message — AUTHORSHIP-GUARDED like msg-edit |
| `slack-api.sh react-add / react-remove <ch> <ts> <emoji>` | **remove** a reaction (MCP only adds); enables the eyes→check→remove-eyes review flow |
| `slack-api.sh open-conversation <uid[,uid,...]>` | **create-if-not-exists** a DM/group DM (prints channel id); step 1 of drafting to a never-messaged combo |
| `slack-api.sh status <uid>` | **read presence + status/PTO/meeting/huddle** for any user (read-only; status *setting* stays impossible) |

No `drafts-*` or status-*setting* subcommands exist and none can be added — drafts are the internal client API, and setting status needs an ungranted scope (`status` above is read-only). Reaction emoji names take NO colons (`white_check_mark`, `eyes`, `thankyou`). Every write is real and visible → confirmation rules apply (reactions may follow an instructed task; deletes/deschedules/sends need explicit go-ahead).

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

**Moved to `references/people-org.md`** (2026-07-24), which now holds the full identity map (Slack/email/GitLab/Jira IDs, timezones), name-disambiguation rules, per-person dossiers with DM channel IDs, gatekeeper routing, and org/meeting structure. Load it before resolving any colleague's identity or drafting to a person. Quick rules that remain here: verify new people with `slack_search_users`, `glab api "users?search=<name>"`, and `jira-api GET '/rest/api/3/user/search?query=<name>'` rather than guessing — email is the reliable join key.

## Slack Status (PTO / meetings)

Conventions: `:palm_tree:` emoji with a status like "PTO" when on vacation; similar statuses for meetings/appointments.

**Setting status: impossible** (as of 2026-07-22): the MCP exposes no status tool and `users.profile:write` is not granted. If Mike asks to set his status, say so and ask him to set it manually — and re-check the tool roster occasionally, since Slack is actively expanding the MCP server. Posting to `#tech-availability` (which *is* possible, as a normal message) covers the "I'm stepping away" use case.

**Reading OTHERS' status/presence: works** (verified 2026-07-24): `slack-api.sh status <uid>` prints presence (active/away), current status emoji+text (e.g. `:spiral_calendar_pad: In a meeting • Google Calendar`, `:palm_tree:` PTO), expiration, and huddle participation. The MCP's `slack_read_user_profile` also includes the status line. Use it before drafting a ping — meeting/PTO/away detection is cheap and read-only.
