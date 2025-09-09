---
atlassian:
  cloud_id: "8fd1c100-2018-43ac-bdc1-ca69369799c3"
  instance_url: "https://bstock.atlassian.net"
gitlab:
  # 3MP Service Project IDs (cacheable values)
  three_mp_services:
    account: "522"
    auction: "582"
    contract: "759"
    dispute: "504"
    docserv: "565"
    erp: "605"
    ingestion: "661"
    integration: "770"
    listing: "628"
    location: "546"
    offering: "735"
    order: "515"
    order_process: "722"
    payments_methods: "520"
    payments_transactions: "519"
    risk: "802"
    saved_search: "798"
    search: "603"
    shipment: "524"
    subscription: "577"
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
- `cops-portal` - nextjs portal for `/cops/*` URLs (Client Operations)

- `fe-core` - a shared component and utility library published as an npm package
- `fe-scripts` - a set of utility functions and help pages for bstock engineers
- `bstock-eslint-config` - shared linter config

- I have access to other projects which I have not checked out locally

Whenever I refer to "my projects", I am usually referring to the five portals,
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

When working within a project directory, always prefer to `cd` into the
directory _rather than_ operating on files in that project from another location

The Claude permissions whitelist does not understand these command arguments and
will ask me to approve all of your commands.

**For Example:**
Do not:  
`git -C /path/to/project/directory status`

Instead do this:  
`cd /path/to/project/directory && git status`

### Managing Dependencies

**IMPORTANT**: Run `npm ci` when creating new branches or when encountering linter/test failures unrelated to your changes:

- Dependencies can become out of sync when switching between branches
- Always run `npm ci` after creating a new branch unless you just did this for the HEAD commit the branch is based on

### Development Servers

Use the `run_in_background` parameter for long-running processes like development servers to avoid blocking the terminal.

**Examples:**

- ✅ `Bash(npm run dev, run_in_background=true)` - Runs in background, allows continued work
- ❌ `Bash(npm run dev)` - Blocks terminal indefinitely
- ✅ Use `BashOutput` tool to monitor background process output when needed

### Build Commands

**NEVER RUN BUILD COMMANDS.** Build commands are expensive, time-consuming operations that are not necessary for development work. They should only be run by CI/CD systems or when explicitly requested by the user.

**Examples:**

- ❌ `Bash(npm run build)` - Never do this
- ❌ `Bash(npm run build:prod)` - Never do this
- ✅ Use type-checking and linting commands instead for code validation

### Performance Optimization for Long-Running Commands

**Long-running commands** like `npm run lint`, `npm run eslint`, or `npx eslint` can take significant time to complete. When there's a reasonable chance Claude will need to reference the output multiple times, cache the results to improve performance:

**Cache command output using temporary files:**

```bash
# Generate unique temporary file to prevent collisions
TEMP_FILE=$(mktemp /tmp/lint_output.XXXXXX)
npm run lint > "$TEMP_FILE" 2>&1

# Or use a descriptive filename with random suffix
npm run lint > "tmp/lint_$(date +%s).txt" 2>&1
```

**Then operate on the cached file:**

```bash
# Search for specific patterns
grep "error" "$TEMP_FILE"
grep "warning" "$TEMP_FILE" | head -10

# Count issues by type
grep -c "error\|Error" "$TEMP_FILE"
```

**Benefits:**

- Avoid re-running expensive commands
- Enable efficient pattern searching with `grep`
- Allow multiple analysis passes on the same output
- Prevent command timeout issues with large codebases

**When to use caching:**

- Commands taking >30 seconds to complete
- When you need to analyze output multiple times
- For commands with large output that benefit from grep/filtering
- During iterative debugging workflows

**Important: Handling Commands That Exit With Non-Zero Status**

Commands like `npm run lint` exit with non-zero status when errors are found, which breaks `&&` chains. The output is still captured, but subsequent commands don't execute:

```bash
# ❌ This won't echo because lint has errors (non-zero exit)
npm run lint > /tmp/lint.txt 2>&1 && echo "Done"

# ✅ This works - output is captured regardless of exit status
npm run lint > /tmp/lint.txt 2>&1
echo $? # Shows exit code (non-zero if errors)
ls -la /tmp/lint.txt # Verify file was created

# ✅ Alternative: Use ; instead of && to run commands regardless
npm run lint > /tmp/lint.txt 2>&1; echo "Output saved to /tmp/lint.txt"
```

**Verification Pattern:**

```bash
# Always verify the file was created and contains expected content
ls -la /tmp/lint.txt
head -n 5 /tmp/lint.txt
```

## IDE-Based Diagnostics Workflow

**For efficient ESLint/TypeScript violation resolution, use IDE diagnostics instead of expensive CLI commands.**

See user-space CLAUDE.md for complete IDE workflow documentation including step-by-step processes, tool behavior analysis, and file state detection strategies.

### Integration with Cached Output for B-Stock Projects

Combine cached lint output with IDE diagnostics for comprehensive analysis:

```bash
# Cache full codebase analysis for overview
npm run lint > /tmp/lint.txt 2>&1

# Then use IDE diagnostics for targeted real-time fixes
cursor /path/to/specific/file.tsx
# Use mcp__ide__getDiagnostics for immediate feedback
```

## B-Stock Microservices API Documentation

### Accessing Swagger Documentation for 3MP Services

All B-Stock microservices following the `@b-stock/SERVICE_NAME-api-client` naming convention have swagger.json documentation available in their GitLab repositories.

**Standard Convention Pattern:**

- **API Client Package**: `@b-stock/SERVICE_NAME-api-client`
- **GitLab Repository**: `b-stock/code/three-mp/svc/SERVICE_NAME`
- **Project ID**: Available in YAML frontmatter above

**Steps to Retrieve Swagger Documentation:**

1. **Use cached project ID** from YAML frontmatter above (preferred for performance)
2. **Get swagger file** using GitLab MCP tools:
   ```
   mcp__gitlab__get_file_contents({
     project_id: "PROJECT_ID_FROM_CACHE",
     file_path: "swagger.json",
     ref: "main"
   })
   ```

**If service not in cache:**

1. **Search for repository**: `mcp__gitlab__search_repositories({ search: "SERVICE_NAME" })`
2. **Extract project_id** from results (add to cache for future use)
3. **Get swagger file** using the project_id as above

**Naming Convention Exceptions:**

- **`ingestion`**: Uses `ingestion-nestjs` (ID: 661) as the active service. The `ingestion-old` repository is archived.
- **`saved-search`**: Uses the 3MP version (ID: 798) at `b-stock/code/three-mp/svc/saved-search`, not the legacy version at `b-stock/code/svc/saved-search`.
- **Payment services**: Located under nested paths:
  - `payments-methods` → `b-stock/code/three-mp/svc/payments/methods`
  - `payments-transactions` → `b-stock/code/three-mp/svc/payments/transactions`

All services follow the same `swagger.json` at repository root pattern regardless of these path variations.

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

### MCP Tool Verification Checklist
Before planning workflows that use MCP tools, Claude MUST:

1. **Test GitLab MCP availability**: `mcp__gitlab__search_repositories`
2. **Test Atlassian MCP availability**: `mcp__atlassian__getVisibleJiraProjects`
3. **If unavailable**: Prompt user to run `/mcp` command first
4. **Check token permissions**: GitLab may be read-only without `BSTOCK_GITLAB_TOKEN`

## Git source control workflows

### Commit Message Formatting

**Individual commits within a branch** do NOT require semantic version prefixes (MAJOR:, MINOR:, etc.). Use standard descriptive commit messages.

**GitLab Merge Request titles** MUST include semantic version prefixes because these titles become the squash-merge commit message and trigger automated versioning.

**Examples:**

- ✅ Branch commit: `Add TypeScript strict mode configuration`
- ✅ Branch commit: `Fix failing tests in ManifestTable component`
- ✅ MR title: `MINOR: SPR-4490 Enable noUncheckedIndexedAccess foundation for fe-core`

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

**Coverage Parsing Issue**: The GitLab MCP tools (`get_pipeline`,
`retry_pipeline`) have a parsing bug where they expect pipeline coverage to be a
number, but some GitLab pipelines return coverage as a string (like "85.5%" or
"N/A"). This causes these tools to fail with the error:

```
MCP error -32603: Invalid arguments: coverage: Expected number, received string
```

**Workarounds**:

- Use `list_pipelines` to check pipeline status instead of `get_pipeline`
- The `retry_pipeline` tool actually WORKS despite the error message - the
  pipeline retry action succeeds, but the response parsing fails. Use the tool
  and ignore the coverage-related error message.
- Manual pipeline retry through GitLab UI is an alternative if you prefer
- For projects with coverage reporting enabled, expect parsing errors but the
  actions still work

**Merge Request Configuration API**: The GitLab MCP tools support configuring MR settings:

- **Delete Source Branch**: Use parameter `remove_source_branch: true`
  - This sets `force_remove_source_branch: true` in the MR
  - Checkbox will be checked in GitLab UI: "Delete source branch"
- **Squash Commits**: Use parameter `squash: true`
  - This sets `squash: true` in the MR
  - Checkbox will be checked in GitLab UI: "Squash commits"
  - **Note**: Not all projects allow users to modify squash settings due to project permissions

**Default MR Creation Settings**: When creating new merge requests with `create_merge_request`, Claude should ALWAYS include these parameters by default unless instructed otherwise:

- `remove_source_branch: true`
- `squash: true`

This ensures the "Delete source branch" and "Squash commits" checkboxes are pre-checked when the MR is created.

**Merge Request Merging Limitation**: The GitLab MCP tools do NOT support merging merge requests programmatically. The standard GitLab API has a `PUT /projects/:id/merge_requests/:merge_request_iid/merge` endpoint, but the MCP server doesn't implement it.

**Workaround for Merging**:

- Configure MR settings using the methods above
- Use the macOS `open` command to open the MR URL in the browser: `open "https://gitlab.bstock.io/..."`
- User must manually click the "Merge" button in the GitLab web interface
- After manual merge, Claude can handle cleanup (verify merge, pull latest, delete local branches)

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

When creating MRs, **ALWAYS ADD** the creator of the MR as an assignee unless
otherwise specified.

#### Merge Request Body

The Merge Request body should use the default Merge Request template as a base.
Fill out the appropaite body section with a description of the changes to be
reviewed. Keep in mind, the audience for this text is other engineers who will
be reviewing the code in this branch.

### Package Version Management

**CRITICAL: NEVER MANUALLY UPDATE THE PROJECT "VERSION" KEY IN PACKAGE.JSON**

- The project's own version number (the "version" key) in `package.json` is managed automatically by CI/CD systems
- Manual updates to the project version will cause CI failures and deployment issues
- Version bumps are triggered by semantic version prefixes in MR titles (MAJOR:, MINOR:, PATCH:)
- The automated versioning system uses semantic-release to determine appropriate version numbers
- **Claude MUST NOT modify the "version" field in package.json files under any circumstances**

**Note**: This restriction applies ONLY to the project's own "version" field. Claude can and should update dependency versions in "dependencies", "devDependencies", and "peerDependencies" when instructed.

#### Automated Release Pipeline Process

When a feature branch with semantic version prefix (MAJOR:, MINOR:, PATCH:) is merged into `main`, the following automated pipeline sequence occurs:

**Pipeline 1 - Version Bump:**
1. **`bump_version` job** executes in "version" stage after linting, testing, and build jobs pass
2. Uses `semantic-release` npm package to:
   - Update `package.json` and `package-lock.json` version numbers
   - Replace `{VERSION_DATE}` tokens in `CHANGELOG.md` with actual version and date
   - Create commit with message format: `chore(release): X.Y.Z`
   - Create and push new git tag for the release
   - Push changes back to `main` branch

**Pipeline 2 - Package Publication:**
1. **`publish-package` job** executes automatically after version bump commit
2. Builds and publishes the new package version to B-Stock npm registry
3. Makes new version available for consumption by portal projects

#### Monitoring Package Releases with GitLab MCP Tools

To verify package publication status, use GitLab MCP tools to inspect pipeline jobs:

```javascript
// 1. List recent pipelines on main branch
mcp__gitlab__list_pipelines({ project_id: "PROJECT_ID", ref: "main", per_page: 5 })

// 2. Check for successful bump_version job (indicates semantic-release completed)
mcp__gitlab__list_pipeline_jobs({ project_id: "PROJECT_ID", pipeline_id: "PIPELINE_ID" })
// Look for: stage: "version", name: "bump_version", status: "success"

// 3. Find subsequent pipeline with chore(release) commit (the publishing pipeline)
// Look for commit.title: "chore(release): X.Y.Z" by semantic-release-bot

// 4. Verify publish-package job completion
mcp__gitlab__list_pipeline_jobs({ project_id: "PROJECT_ID", pipeline_id: "PUBLISH_PIPELINE_ID" })
// Look for: stage: "build", name: "publish-package", status: "success"
```

**Key Pipeline Identifiers for Monitoring:**
- **Version bump pipeline**: Contains `bump_version` job in "version" stage
- **Publishing pipeline**: Contains `publish-package` job in "build" stage
- **Release commit**: Title format `chore(release): X.Y.Z` by `semantic-release-bot`

**Common Projects to Monitor:**
- `fe-core` (project_id: "506")
- `bstock-eslint-config` (project_id: "525")

This process ensures all package publications are traceable and verifiable through GitLab pipeline inspection.

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

- **Issue Links**: Cannot create ticket relationships programmatically
  - e.g. "blocks/is blocked by"
- **Sprint Assignment Format**: The `customfield_10018` (Sprint) field expects a direct number, not an array
  - ❌ Wrong: `{"customfield_10018": [2331]}`
  - ✅ Correct: `{"customfield_10018": 2331}`

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

#### Jira Ticket Creation Guidelines

**Parent Epic Assignment**: Most Jira tickets outside of the `BUGS` project should have a parent epic to ensure visibility to managers and product leads. When creating a new ticket, always ask what parent epic it belongs to.

**Common Catch-All Epic**: For technical debt, performance improvement, or developer experience tickets, use the "Optimization Cabal" epic at **GLOB-1987** as a common parent.

**Default Project Assignment**: When creating Jira tickets that are not immediately assigned to the user, default to the `GLOB` project unless specified otherwise.

##### Ticket Title Formatting Conventions

Jira ticket titles should follow these formatting patterns observed in the Optimization Cabal epic (GLOB-1987):

**Project/Service Tags**: Use bracketed tags to indicate the affected project(s) or service(s):
- `[SPIKE]` - Research or prototyping work that is not QA-testable
- `[fe-core]` - Frontend core shared library
- `[AP]` - Accounts Portal
- `[BP]` - Buyer Portal  
- `[SP]` - Seller Portal
- `[CSP]` - CS Portal
- `[HP]` - Home Portal
- `[FE]` - General frontend work
- `[Account svc]`, `[Search svc]` - Backend services
- `[SP/CSP]`, `[FE Portals]` - Multiple projects

**Multiple Tags**: Can combine multiple tags for cross-cutting work:
- `[SPIKE] [Notification]` - Research work on notifications
- `[Potential to split][FE Portals]` - Large work that may need division

**Title Structure**: After tags, use descriptive titles that clearly state the work:
- Start with action verbs when possible (Fix, Update, Remove, Audit, etc.)
- Be specific about what is being changed
- Keep total title length reasonable

**Examples from GLOB-1987 children**:
- `[SPIKE] Evaluate parallelized tests through Jira/Vitest sharding in CI`
- `[fe-core] Fix logging context token + trace details` 
- `[SP] Update deprecated 'legacyBehavior' Next Link component`
- `[SP/CSP] Audit Inventory/Listing/Order/Dispute columns for consistency`

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

When a ticket needs to be **Closed** (not "Done"), this indicates the work will
not be completed or is no longer relevant. The "Closed" status is distinct from
"Done" and has a different workflow path:

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
- Always use "Close" when explicitly requested instead of following the normal
  Done workflow
- The Close transition is only available from "To Do" status
