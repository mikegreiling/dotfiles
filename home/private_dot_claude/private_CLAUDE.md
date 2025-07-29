# Claude Code User Memory

My name is "Mike Greiling". I also go by "Michael" but prefer "Mike". I am a
professional software engineer with a background in TypeScript, React, and
NextJS. When interacting with me, presume a base level of competence and
understanding.

I do not want Claude to tell me what it thinks I want to hear. Treat all of my
prompts as though I appended "correct me if I'm wrong" to the end of it. I want
Claude to push back if I am incorrect about an assumption.

I want Claude to notice when certain workflows could be optimized to use fewer
prompts and tool calls, for instance if a certain stable value needs to be
looked up using MCP integrations (like a project ID or user ID) prior to doing
an operation with them, suggest we cache this value within Claude's memory files

I maintain my terminal dotfiles including base Claude memory files within a
`chezmoi` dotfiles repository, and any changes to `bash` or `zsh` config, my
macOS applications managed by `brew`, `Claude` slash commands, mcp config, or
memory files SHOULD ALWAYS BE committed into this dotfiles repository. Prompt me
to do so whenever necessary.

If an attempt to apply `chezmoi` changes attempts to interact with the user and
prevents Claude from utilizing it, Claude should NEVER attempt to use `--force`
to apply changes. Doing so is a destructive action that can overwrite changes
I have made to my local files. Utilize `chezmoi status` first and inform me
about potential blockers.

## Bash/terminal command quirks

Claude Code will block Claude from executing `cd` to directories that I have not
already added as an approved "working directory". If this happens Claude will
receive an error like: `Error: cd to '/path/to/directory' was blocked.`

When this happens, we can add this directory into the whitelist by utilizing the
`List(/path/to/directory)` tool which will prompt me to add the directory as a
working directory for the session and then attempt to execute the `Bash` command
again.

## Git workflow

Default git branches are usually `main` or `master`. Do NOT ever commit changes
to a "default" branch.

Non-default branches (not `main` or `master`) are called "feature branches". All
commits that Claude makes should be made in feature branches. If I ask to commit
changes and I am not on a feature branch, suggest making a new branch or
switching to an existing feature branch first.

### Git branches

New branches SHOULD BE based on the latest HEAD of the default branch. Please
fetch the latest changes from the default origin prior to making a feature
branch whenever possible.

### B-Stock Branch Naming (personal preference applies to bstock-projects)

For B-Stock projects, use this specific naming convention:
`mg-JIRA_TICKET-kebab-case-branch-name`

- `mg` are my initials
- `JIRA_TICKET` is the Jira ticket associated with this work (if one exists).
  This can be omitted for ad-hoc work.
- `kebab-case-branch-name` is a simple branch name succinctly describing the
  changes we intend to make within the branch.

The branch name SHOULD NOT exceed 42 characters total

Example: `mg-SPR-4400-add-risky-accounts-table`

If any of this is ambiguous, ask me for clarification.

### B-Stock GitLab Account

My B-Stock GitLab username is `mike.greiling` (ID: 421)

#### GitLab Workflow Reminders

- When creating merge requests, always assign them to the creator (which will be
  me when using my token)
- My GitLab user ID of 421 is only applicable to B-Stock's GitLab instance, not
  GitLab.com

### B-Stock Atlassian Account

We use Jira issues to track work across B-Stock engineering teams. These issues
are interchangably referred to as either "ticket", "issue", or "story". If you
see one of those terms it likely refers to a Jira issue. I commonly use "ticket"

We DO NOT use GitLab issues at B-Stock. If I ask you to do something related to
an issue, ticket, or story DO NOT use the GitLab MCP tools to achieve this.

For B-Stock projects, my Atlassian (Jira/Confluence) User Account ID is:
`712020:102e13ca-76c4-4a0c-89e1-c9fc45369c5d`

This ID should be used when:

- Assigning tickets to me in Jira
- Filtering tickets by assignee
- Creating tickets with me as the creator

### Team Sprinters (SPR) Project Details

- **Project Key**: `SPR`
- **Project ID**: `10059`
- **Board ID**: `59`

@bstock-current-sprint-cache.md

## Jira/GitLab ticket workflow

Claude has access to tool commands for both Jira (through Atlassian) and GitLab.
These tools allow Claude to handle workflows relating to my work assignments.
Every git branch I push to GitLab should have a corresponding Merge Request (MR)
associated with it. And every merge request should be associated with at least
one or more Jira tickets. When creating a MR, Claude should ask me which Jira
ticket it is associated with. Suggest a ticket based on the list of assigned
tickets for the currently active sprint. Most of my tickets will be prefixed
with `SPR-*` because I am on "Team SPRINTERS". If no existing ticket matches the
work being done on the current branch Claude can create a new Jira ticket within
Team SPRINTERS, give it an appropriate description, assign it to me, and move it
into the currently active sprint. Ask for verification before doing this.

When a Jira ticket is associated with a GitLab merge request, the Jira ticket
should be incorporated into the MR title after its semantic version prefix
e.g. `MINOR: SPR-2019 Fix FooBar Component`.

### Marking a Jira ticket as "complete".

Note that based on the project the ticket is associated with, there is usually a
multi-step process that a ticket must go through. e.g. "to do" -> "in progress"
-> "technical review", etc.

Note that when I ask to mark a ticket as "complete", I DO NOT want you to change
its status to "closed". The "closed" status means that a ticket is not resolved
and is completely distinct from the "done" status.

## GPG Signing Configuration

If commit fails with `gpg: signing failed: No pinentry`, inspect our custom
pinentry script and ensure that `pinentry-mac` is installed via homebrew.

### Browser URL Opening

Claude can open URLs in the user's default browser using the macOS `open` command:

- Use: `open "https://example.com"`
- Always offer to open relevant URLs when providing manual workaround instructions
- This works for Jira tickets, GitLab merge requests, documentation, etc.

## Self-Improvement and API Learning

When using MCP tools (GitLab, Atlassian/Jira/Confluence, etc.), Claude SHOULD
ALWAYS document API quirks, cache stable values, and record workarounds in
appropriate CLAUDE.md files. Claude MUST suggest storing frequently-used stable
values (project IDs, field IDs, cloud IDs) in context files to optimize future
workflows.

### Context File Organization

- **User-space** (`~/.claude/CLAUDE.md`): Personal behavior, team info
- **Organization-space** (`~/Projects/bstock-projects/CLAUDE.md`): Company metadata, APIs
- **Project-space** (`project/CLAUDE.md`): Project-specific technical metadata

Use YAML frontmatter for structured metadata (project_id, cloud_id, etc.).

DO NOT GUESS PROJECT ID VALUES. If context lacks a needed project_id, introspect
using MCP tools and suggest adding to context documents.

## MCP Tool Availability

If I prompt you to utilize an MCP tool to accomplish a task (GitLab, Atlassian,
or Context7 being common examples) and you DO NOT have these tools available,
tell me this so I can fix them. DO NOT EVER fall back to attempting to use the
GitLab or Atlassian APIs directly via cURL or other similar methods unless I
have explicitly instructed you to do so.
