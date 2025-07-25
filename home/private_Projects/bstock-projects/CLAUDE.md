---
atlassian:
  cloud_id: "8fd1c100-2018-43ac-bdc1-ca69369799c3"
  instance_url: "https://bstock.atlassian.net"
---

# B-Stock Projects Memory

This file contains B-Stock specific configuration and cached values for all
projects within the bstock-projects directory.

## About B-Stock's architecture

B-Stock uses microservices + frontend portals deployed to four environments:

- `bstock-dev.com` (auto-deployed after merging to `main`)
- `bstock-qa.com`, `bstock-staging.com` (manual deployment)
- `bstock.com` (production)

Dev/QA environments require VPN access.

## About this directory

I am primarily a frontend engineer. This `bstock-projects` directory houses
several projects I commonly work within. Among them are:

- `accounts-portal` - vite portal for `/acct/*` URLs
- `cs-portal` - nextjs portal for `/csportal/*` URLs
- `seller-portal` - nextjs portal for `/seller/*` URLs
- `home-portal` - nextjs portal for `/`, `/all-auctions/*`, and `/buy/*` URLs

- `fe-core` - a shared component and utility library published as an npm package
- `fe-scripts` - a set of utility functions and help pages for bstock engineers
- `bstock-eslint-config` - shared linter config

- I have access to other projects which I have not checked out locally

Whenever I refer to "my projects", I am usually referring to the four portals,
plus `fe-core`. So if I say, do X or Y in all of my projects, I mean to say that
I'd like Claude to perform that action within the aforementioned projects'
sub-directories.

## Managing Project Context

All projects within this directory should have their own `CLAUDE.md` memory file
containing important context for that project.

Before executing ANY Bash commands or MCP tools relating to these projects,
Claude MUST FIRST LOAD THE CLAUDE.md FILE FOR THAT PROJECT INTO ITS MEMORY:

1. Check if the CLAUDE.md for that project exists within Claude's system context
2. If not, read it explicitly using `Read(./project-name/CLAUDE.md)` to load
   the project-specific context into the context window.
3. Then proceed with the requested operation.

**Example:**
If I prompt you to create a new branch in `fe-core`, and you do not already have
knowledge of the contents of `fe-core/CLAUDE.md`, you MUST read that file PRIOR
TO executing something like `Bash(cd fe-core && git checkout -b new-branch)`.

## Working in Project Directories

When working within a project directories, always prefer to `cd` into the
directory _rather than_ operating on files in that project from another location

The Claude permissions whitelist does not understand these command arguments and
will ask me to approve all of your commands.

**For Example:**
Do not:  
`git -C /path/to/project/directory status`

Instead do this:  
`cd /path/to/project/directory && git status`

## Sub-Agent Tasks in Project Directories

When planning to using the `Task` tool to perform parallel actions in multiple
projects, and those actions will utilize MCP tools like GitLab or Atlassian,
please first ensure that those MCP tools are enabled and authenticated. The
GitLab MCP tool might be configured with a default read-only token if the user
has not provided a personal `BSTOCK_GITLAB_TOKEN`, so if that environment var is
not visible to you, it may mean you cannot do things like create merge requests,
review code, or write notes. If the Atlassian tools are not available to you,
it might mean the user needs to authenticate using the `/mcp` command first.

Perform these checks PRIOR TO running the `Task` command and prompt the user to
fix any missing MCP functionality first.

## Git source control workflows

When creating a new branch:

- First, fetch the latest changes from `origin/main` if we have not done so
  recently and base the new branch on this unless prompted to do otherwise
- Incorporate the Jira ticket ID for this work (if known) into the branch name
  along with a short, succinct, kebab-case descriptor of the changes.
  - If the Jira ticket for current work is not known or uncertain, ask.
  - If a Jira ticket does not yet exist, ask whether we should create one.
- The full branch name should not exceed 42 characters.

When pushing a branch:

- Unless pormpted otherwise, use the `--no-verify` flag to bypass automated
  linting. Linting should have already been done by Claude. If it has not, do
  this manually when appropriate.

After pushing the branch:

- A GitLab merge request should be created for the branch in the appropriate
  project if there is not already one in place. The response from the server
  following the `git push` should indicate whether a MR already exists.

## GitLab workflows

### GitLab MCP tools

Claude has access to "gitlab" MCP tools to perform actions on B-Stock's self-
hosted GitLab server. The MCP server is configured in each B-Stock project's
root `.mcp.json` file with a default token that has read-only access. Users
SHOULD provide their own `BSTOCK_GITLAB_TOKEN` environment variable with a
personal access token to gain broader permissions. If a gitlab tool call
responds with a 403 or 401 error response, prompt the user to configure a
personal access token.

If you do not know the user's username, ask for it. Do not guess.

#### GitLab MCP Tool Limitations

**Coverage Parsing Issue**: The GitLab MCP tools (`get_pipeline`, `retry_pipeline`) have a parsing bug where they expect pipeline coverage to be a number, but some GitLab pipelines return coverage as a string (like "85.5%" or "N/A"). This causes these tools to fail with the error:

```
MCP error -32603: Invalid arguments: coverage: Expected number, received string
```

**Workarounds**:
- Use `list_pipelines` to check pipeline status instead of `get_pipeline`
- The `retry_pipeline` tool actually WORKS despite the error message - the pipeline retry action succeeds, but the response parsing fails. Use the tool and ignore the coverage-related error message.
- Manual pipeline retry through GitLab UI is an alternative if you prefer
- For projects with coverage reporting enabled, expect parsing errors but the actions still work

### GitLab Merge Request (MR) Guidelines

#### Merge Request Titles

Merge Requests on B-Stock projects SHOULD ALWAYS start with a semantic version
prefix in its title:

- `MAJOR:` - Breaking changes that require major version bump
- `MINOR:` - New features or functionality (non-breaking)
- `PATCH:` - Bug fixes or minor improvements
- `NO-RELEASE:` - Changes that don't require a release (docs, tests, etc.)

Following this prefix, MR titles should contain the Jira ticket ID (or IDs)
associated with the work in this branch. If no Jira ticket is associated with
this work, ask for clarification or offer to create a Jira ticket first.

Following this, the title should contain a brief, succinct description of the
work done in this branch. The full title of the MR SHOULD NOT EXCEED 128
characters.

**Example MR Title:**

```
MINOR: JIRA-123 Brief description of changes
```

If Claude encounters a MR title for which the semantic version prefix is wrong,
the Jira ticket is wrong or incomplete, or the description is outdated, it
should suggest an update.

#### Merge Request Assignee

Merge Requests SHOULD ALWAYS HAVE an assignee. If the MR does not have an
assignee, it should be set to the creator of the MR unless otherwise specified.

#### Merge Request Body

The Merge Request body should use the default Merge Request template as a base.
Fill out the appropaite body section with a description of the changes to be
reviewed. Keep in mind, the audience for this text is other engineers who will
be reviewing the code in this branch.

### Changelog Requirements

MOST B-Stock projects contain a `CHANGELOG.md` file in their root directory

- `MAJOR` and `MINOR` changes MUST include entries within `CHANGELOG.md`
- `PATCH` and `NO-RELEASE` changes CAN OPTIONALLY include changelog updates
- The `{VERSION_DATE}` token will be replaced with the current version and date
  via an automated CI job after a branch has been merged

##### CHANGELOG.md Entry Format:

```markdown
## {VERSION_DATE}

### [Breaking|Nonbreaking]

- [TICKET-ID](https://bstock.atlassian.net/browse/TICKET-ID) Brief description of changes
  - Detailed bullet point 1
  - Detailed bullet point 2 (if needed)
```

If a MR is created for a branch with `MAJOR` or `MINOR` in its title and there
is not a corresponding `CHANGELOG.md` entry, a CI job will fail.

## Atlassian worlflows

### Atlassian MCP tools

Claude should have access to atlassian tools to interact with Jira tickets and
Confluence pages. If these are unavailable to Claude, the user likely needs to
authenticate with atlassian using the `/mcp` slash command.

Common Metadata Fields:

- **Story Points**: `customfield_10049`
- **Sprint**: `customfield_10018`
- **Epic Link**: `customfield_10013`

Common API limitations:

- **Story Points**: Cannot be updated programatically via standard edit API
- **Issue Links**: Cannot create ticket relationships programmatically
  - e.g. "blocks/is blocked by"

When a task cannot be accomplished due to API limitations:

- Provide manual instructions with specific steps
- Include resource URLs to relevant interfaces
- Offer to open URLs using the `open` command if on macOS
- Document the limitation within `CLAUDE.md` for future reference

### Atlassian Jira Workflows

Jira is a ticketing system used to track work across B-Stock engineering teams.
Jira tickets are formatted with 2-4 letters matching the project, a dash, and a
3-4 digit number. (**Example**: `SPR-2048`).

#### Common Jira Projects

- **SPR** (Team Sprinters)
- **MULA** (Team MULA)
- **TBD** (Team TBD)
- **ZRO** (Team ZERO)
- **WRH** (Team WRH)
- **GLOB** (3MP Global)
- **BUGS** (Bug Triage Project)

#### Jira Ticket Status Workflow

Tickets must go through a specific set of status "transitions" to ultimately get
to their "completed" (Done) state. What follows is the normal sequence of status
values and transitions for tickets in the following projects: `SPR`, `MULA`,
`TBD`, `ZRO`, `WRH`, `GLOB`. Other projects (like `BUGS`) follow completely
different statuses and transition patterns.

##### Complete Workflow Sequence (To Do → Done)

The standard path to mark a ticket as "Done":

1. **To Do** → **In Progress** (transition: "Start Work", id: 11)
   - Begin working on the ticket

2. **In Progress** → **Technical Review** (transition: "Merge Request", id: 21)
   - When ticket's work (GitLab merge requests) is ready for code review

3. **Technical Review** → **Merged** (transition: "Merge", id: 31)
   - When ALL associated merge requests have been merged or closed

4. **Merged** → **Quality Review** (transition: "Ready for QA", id: 41)
   - Ticket awaits QA engineer feedback

5. **Quality Review** → **Done** (transition: "QA BYPASS", id: 211)
   - Use QA BYPASS when bypassing QA process (requires "nontestable" label)

##### QA Workflow Decision Logic

When transitioning to **Quality Review**:

- **If "nontestable" label exists**: Use "QA BYPASS" to go directly to Done
- **If no "nontestable" label**: Check for "Acceptance Criteria" section in description
  - **Missing Acceptance Criteria**: Prompt to add QA testing instructions to ticket description
  - **Has Acceptance Criteria**: Leave in Quality Review for QA engineer to use "QA PASS"

##### Important QA Workflow Rules

- **QA PASS** (id: 51): Only QA engineers can use this transition - developers should NOT use this
- **QA BYPASS** (id: 211): Should only be used when bypassing normal QA process
  - ALWAYS prompt for confirmation before using QA BYPASS
  - ALWAYS ask to apply "nontestable" label when using QA BYPASS
  - Only use for tickets that don't require QA testing
  - Can be used immediately if "nontestable" label already exists

##### Alternative Transitions Available

- **MR Fail**: Goes back to In Progress from Technical Review or Merged
- **Rework**: Goes back to In Progress from Done or Quality Review
- **QA Block**: Goes to Blocked status from Quality Review
- **Stop Work**: Goes to To Do from In Progress
- **Work Block**: Goes to Blocked from In Progress or To Do

##### Reverting from Done

If a ticket needs to be reopened from Done status:

- **Rework** (id: 181): Back to In Progress
- **Reopen** (id: 81): To Reopened status
- **QA** (id: 231): Back to Quality Review

##### Closing Tickets (Distinct from "Done")

When a ticket needs to be **Closed** (not "Done"), this indicates the work will not be completed or is no longer relevant. The "Closed" status is distinct from "Done" and has a different workflow path:

**Path to Close a Ticket:**

1. **From any status** → **To Do** (use appropriate transition to get back to To Do)
   - Use "Stop Work" (id: 111) from In Progress
   - Use "Rework" or other appropriate transitions from other statuses

2. **To Do** → **Closed** (transition: "Close", id: 191)
   - This marks the ticket as Closed with appropriate resolution
   - Common resolutions include "Won't Do", "Duplicate", "Cannot Reproduce", etc.

**Important Distinctions:**
- **"Done"** = Work completed successfully and delivered
- **"Closed"** = Work not completed or no longer needed
- Always use "Close" when explicitly requested instead of following the normal Done workflow
- The Close transition is only available from "To Do" status
