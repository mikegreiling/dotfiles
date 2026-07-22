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
- There is **no tool to list, read, update, or delete drafts** — the create call is the entire draft surface, and no tool consumes `draft_id`; its only use is the write-confirmation sentinel above. Never claim a draft exists or was updated based on a success message alone.
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

### Message formatting via MCP (verified 2026-07-22)

Standard markdown converts correctly: bold/italic/strikethrough, inline code, fenced code blocks, blockquotes (nested styling works), `[text](url)` links (they unfurl), numbered and bulleted lists. Two caveats:

- **No language hints on fenced code blocks** — ` ```js ` leaks a literal "js" as the block's first line. Use bare ` ``` `.
- Bare mention keywords sent via MCP rendered as plain text (not live mention tokens) in a DM test — but treat that as unconfirmed for real channels; keep bare keywords out of messages unless Mike approved them.

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
