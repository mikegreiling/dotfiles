# Slack Workflow

How the team uses Slack, and how to act there on Mike's behalf via the official Slack MCP server (installed as the `slack` Claude Code plugin). All IDs and emoji names below were verified live on 2026-07-22.

## Posting on Mike's behalf — ground rules

- The MCP connection uses Mike's **user OAuth token**: messages and reactions appear **as Mike**, with no "via app" or AI attribution visible to others. Treat every send/react as Mike speaking.
- Only send messages or add reactions when Mike **explicitly asks** — never as a side effect of another task.
- For anything substantive (announcements, review requests with commentary), prefer `slack_send_message_draft` so Mike reviews and sends it himself; direct `slack_send_message` is fine for simple, explicitly dictated posts.

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
