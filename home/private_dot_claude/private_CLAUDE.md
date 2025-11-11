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

**IMPORTANT**: `chezmoi` should NEVER be used at all whatsoever without first
reading the comprehensive guidelines in `~/.local/share/chezmoi/CLAUDE.md`.

### Chezmoi Workflow - Test Before Committing

**DO NOT EDIT CHEZMOI FILES DIRECTLY**. Instead, follow this workflow:

1. **Make changes directly in your user directory** (e.g., `~/.config/`, `~/.bashrc`, etc.)
2. **Test and validate the changes** work as intended
3. **Use `chezmoi add <file>`** to persist validated changes to the dotfiles repository
4. **Commit the changes** to git

This ensures that all changes are tested before being stored in version control and prevents broken configurations from being committed.

## Bash/terminal command quirks

Claude Code will block Claude from executing `cd` to directories that I have not
already added as an approved "working directory". If this happens Claude will
receive an error like: `Error: cd to '/path/to/directory' was blocked.`

When this happens, we can add this directory into the whitelist by utilizing the
`List(/path/to/directory)` tool which will prompt me to add the directory as a
working directory for the session and then attempt to execute the `Bash` command
again.

### Bash Command Working Directory Persistence

**CRITICAL INSIGHT**: The `cd` command DOES persist between separate Bash tool calls. Each Bash tool call maintains the working directory state from the previous call.

**Common Anti-Pattern to Avoid**:
```bash
# First command (succeeds)
cd project-name && git status

# Second command (fails - we're already in project-name!)
cd project-name && git fetch
# Error: no such file or directory: project-name
```

**Two Solution Strategies**:

**Strategy A - Absolute Paths** (Most Reliable):
```bash
# Always use full absolute paths
cd /full/path/to/project && git status
cd /full/path/to/project && git fetch
```

**Strategy B - Working Directory Awareness** (Most Efficient):
```bash
# First command changes directory
cd project-name && git status

# Subsequent commands work in that directory  
git fetch && git branch --list
```

**When to Use Each Strategy**:
- **Absolute Paths**: When working across multiple projects or when uncertain about current location
- **Directory Awareness**: When working within a single project for multiple consecutive operations
- **Verification**: Use `pwd` when uncertain about current working directory

**Key Takeaway**: Never assume you need to `cd` into the same directory twice in a sequence of Bash commands.

## Package Management - CRITICAL RULES

**NEVER DELETE package-lock.json FILES - EVER!**

Lock files (package-lock.json, yarn.lock, composer.lock, etc.) are critical to maintaining reproducible builds and dependency integrity. They contain the exact resolved versions of all dependencies and their sub-dependencies.

**CRITICAL RULES:**
- **NEVER run `rm package-lock.json`** - This destroys dependency version history
- **NEVER suggest deleting lock files** to "fix" dependency conflicts  
- **NEVER regenerate lock files from scratch** unless explicitly instructed by the user

**Correct approaches for lock file conflicts:**
- Use `git checkout HEAD package-lock.json` to reset to previous state
- Run `npm install` to update lock file based on package.json changes
- Use `npm ci` for clean installs from existing lock files
- Manually resolve conflicts in lock files when necessary

**Why this matters:**
- Lock files ensure all environments use identical dependency versions
- Deleting them can introduce subtle bugs from version differences
- They provide security by preventing supply chain attacks via version pinning
- CI/CD systems rely on lock files for reproducible builds

This rule applies to ALL package managers: npm, yarn, composer, bundler, pip, etc.

## Git workflow

Default git branches are usually `main` or `master`. Do NOT ever commit changes
to a "default" branch.

Non-default branches (not `main` or `master`) are called "feature branches". All
commits that Claude makes should be made in feature branches. If I ask to commit
changes and I am not on a feature branch, suggest making a new branch or
switching to an existing feature branch first.

### Force Push Safety

**NEVER use `git push --force`**. ALWAYS use `git push --force-with-lease` instead. 
The `--force-with-lease` option ensures the push fails if someone else has pushed 
changes in the meantime, preventing accidental overwrites. When instructed to 
"force push," interpret this as a request to use `--force-with-lease`.

### Git branches

New branches SHOULD BE based on the latest HEAD of the default branch. Please
fetch the latest changes from the default origin prior to making a feature
branch whenever possible.

After pulling the latest changes from the default branch and creating a new
feature branch, ALWAYS run the appropriate dependency update command for the
project to ensure dependencies are up to date:

- **Node.js projects**: Run `npm ci` to install exact dependency versions
- **PHP projects**: Run `composer install` to update PHP dependencies
- **Ruby projects**: Run `bundle install` to update gem dependencies
- **Python projects**: Run `pip install -r requirements.txt` or equivalent
- **Other package managers**: Use the appropriate install/update command

This prevents dependency-related build failures and ensures the new branch has
the correct dependency versions that match the current state of the default
branch.

#### Dependency-Related Error Resolution

When encountering failures in linting, type checking, compilation, or other
build-time errors, ALWAYS consider that the failures could be related to
mismatched dependencies. Before investigating code-level solutions, run the
appropriate dependency update command to see if that addresses the issue:

- **First step**: Run `npm ci`, `composer install`, `bundle install`, etc.
- **Then verify**: Re-run the failing command (lint, typecheck, build, test)
- **If still failing**: Then investigate code-level solutions

This is especially important when:
- Switching between branches with different dependency versions
- Working on branches that have been inactive for extended periods
- Encountering unexpected type errors or linting failures
- Build errors that don't seem related to recent code changes

Many apparent code issues are actually resolved by ensuring dependencies are
properly synchronized.

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

### Foundations Pod (FP) Project Details (Primary Team)

- **Project Key**: `FP`
- **Project ID**: `10200`
- **Board ID**: `316`

### Team Sprinters (SPR) Project Details (Former Team)

- **Project Key**: `SPR`
- **Project ID**: `10059`
- **Board ID**: `59`

@caches/bstock-current-sprint-cache.md

## Jira/GitLab ticket workflow

Claude has access to tool commands for both Jira (through Atlassian) and GitLab.
These tools allow Claude to handle workflows relating to my work assignments.
Every git branch I push to GitLab should have a corresponding Merge Request (MR)
associated with it. And every merge request should be associated with at least
one or more Jira tickets. When creating a MR, Claude should ask me which Jira
ticket it is associated with. Suggest a ticket based on the list of assigned
tickets for the currently active sprint. Most of my tickets will be prefixed
with `FP-*` because I am on "Foundations Pod" team. If no existing ticket matches the
work being done on the current branch Claude can create a new Jira ticket within
Foundations Pod, give it an appropriate description, assign it to me, and move it
into the currently active sprint. Ask for verification before doing this.

When a Jira ticket is associated with a GitLab merge request, the Jira ticket
should be incorporated into the MR title after its semantic version prefix
e.g. `MINOR: FP-79 Fix FooBar Component`.

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

**CRITICAL MCP CONNECTION REQUIREMENT**: If you are attempting to create, update, edit, or transition a Jira ticket AND you do not have access to Atlassian's MCP tools (such as `mcp__atlassian__createJiraIssue`, `mcp__atlassian__editJiraIssue`, `mcp__atlassian__transitionJiraIssue`, `mcp__atlassian__getJiraIssue`), then you MUST STOP WHAT YOU ARE DOING AND PROMPT THE USER TO FIX THE MCP CONNECTION instead of proceeding with manual alternatives.

The same requirement applies to GitLab operations requiring MCP tools like `mcp__gitlab__create_merge_request`, `mcp__gitlab__get_merge_request`, etc.

**DO NOT EVER:**
- Fall back to manual ticket creation instructions
- Use GitLab or Atlassian APIs directly via `curl` or similar methods
- Rely on equivalent CLI tools like `gh` or `glab` unless explicitly instructed
- Proceed with workflows that depend on MCP tools when they are unavailable

**INSTEAD:** Immediately prompt the user to run `/mcp` to authenticate the required services before continuing with the requested workflow.

### Jira API Response Optimization

**CRITICAL**: When using `mcp__atlassian__getJiraIssue`, ALWAYS include the `fields` parameter to limit the response size and avoid context window bloat:

```javascript
mcp__atlassian__getJiraIssue({
  issueIdOrKey: "SPR-1234",
  fields: ["summary", "status", "created", "updated", "description", "assignee"]
})
```

**Why this matters**: Jira issue responses can exceed 40,000+ tokens due to extensive metadata (comments, change history, attachments, custom fields, worklogs, etc.). Using field limiting reduces responses to manageable sizes while retaining essential information for analysis.

### IDE Connection Detection and Management

**IDE MCP Tools** (`mcp__ide__*`): These tools provide real-time integration with IDEs like Cursor for diagnostics, code execution, and file management.

**Connection Detection**: Claude should proactively detect whether IDE MCP tools are available by checking for the presence of `mcp__ide__getDiagnostics` in the available function list.

**When IDE Tools Are Unavailable**:
- **Error Response**: Attempting to use IDE tools when disconnected results in: `Error: No such tool available: mcp__ide__getDiagnostics`
- **Automatic Detection**: Claude should detect this state and inform the user
- **User Prompt**: "I notice the IDE diagnostics tools are not available. Please connect your IDE (e.g., run `/ide` command in Cursor) to enable advanced linting and diagnostics workflows."

**Workflow Fallbacks When IDE Disconnected**:
- **Primary**: Use traditional linting commands (`npm run lint`, `npm run type-check`)
- **Secondary**: Use file-based approaches (`Read` + manual analysis)
- **Inform User**: Always explain why IDE-based workflows are unavailable and suggest connection

**Connection State Examples**:
```bash
# IDE Connected - tools available
mcp__ide__getDiagnostics()  # ✅ Works

# IDE Disconnected - tools unavailable
mcp__ide__getDiagnostics()  # ❌ "Error: No such tool available"
```

**Smart Workflow Selection**: Claude should automatically choose the most appropriate workflow based on tool availability:
- **IDE Connected**: Use IDE diagnostics workflows for real-time violation detection
- **IDE Disconnected**: Use npm scripts and file analysis for code quality checks

## IDE Diagnostics Workflow

### Using `mcp__ide__getDiagnostics` for ESLint/TypeScript Violation Detection

The `mcp__ide__getDiagnostics` tool provides real-time access to IDE diagnostics (ESLint and TypeScript violations) and is extremely effective for systematic violation fixing workflows.

#### Tool Behavior and File State Detection

**Key Finding**: The `getDiagnostics` tool behavior varies between specific file queries and global queries:

**Specific File Query** (`getDiagnostics("file:///path/to/file")`):
- **CANNOT differentiate** between these states:
  1. File has never been opened in the IDE
  2. File is open but not yet processed by language servers
  3. File is open but has no violations to report
- All three states return: `{"uri": "file:///.../file.tsx", "diagnostics": []}`

**Global Query** (`getDiagnostics()` without URI):
- **CAN detect file state** by showing ALL currently tracked files
- **Shows files with no violations** - files appear in the list even with empty diagnostics arrays
- **Reliable file state detection** - if a file appears in global diagnostics, it's open and processed

**File State Detection Strategy**: Use global diagnostics to check if a file is currently open/processed by the IDE.

#### Workflow Implications

**Recommended IDE Diagnostics Workflow:**
1. **Open file with delay**: Use `cursor <file-path> && sleep 2` to ensure the file is loaded and processed
2. **Verify file is tracked**: Check that the file appears in global diagnostics (`getDiagnostics()`)
3. **Query specific diagnostics**: Use `mcp__ide__getDiagnostics` with the file URI to get violations
4. **Fix violations systematically**: Address each diagnostic one by one
5. **Verify completion**: Re-check diagnostics to confirm all violations resolved

**Important Workflow Rules:**
- **Always open files with delay** using `cursor file && sleep 2` to ensure processing completion
- **Verify file state** by checking it appears in global diagnostics before proceeding
- **Use global diagnostics** to see all currently tracked files (even those without violations)
- **Don't rely on empty specific diagnostics** alone - always verify file is in global list first

#### Example Workflow

```bash
# 1. Open file with delay to ensure processing
cursor /path/to/component.tsx && sleep 2

# 2. Verify file is being tracked (should appear in global list)
getDiagnostics()  # Check that our file appears in the list

# 3. Check specific file diagnostics
getDiagnostics("file:///path/to/component.tsx")

# 4. Fix violations found

# 5. Re-check to confirm resolution
getDiagnostics("file:///path/to/component.tsx")
```

#### File State Detection Helper

```bash
# Check if a file is currently open/tracked by the IDE:
# 1. Get global diagnostics
global_diags = getDiagnostics()

# 2. Look for the file URI in the results
if "file:///path/to/your/file.tsx" in [item.uri for item in global_diags]:
    print("File is open and being tracked")
else:
    print("File is not currently tracked - need to open it first")
```

#### Diagnostic Response Format

**When violations exist:**
```json
{
  "uri": "file:///path/to/file.tsx",
  "diagnostics": [
    {
      "range": {"start": {"line": 45, "character": 12}, "end": {...}},
      "severity": 2,
      "message": "Forbidden non-null assertion.",
      "source": "eslint(@typescript-eslint/no-non-null-assertion)"
    }
  ]
}
```

**When no violations (or file not processed):**
```json
{
  "uri": "file:///path/to/file.tsx",
  "diagnostics": []
}
```

#### Best Practices

1. **Open files explicitly** before checking diagnostics
2. **Use global diagnostics** to see which files are currently being tracked
3. **Don't rely on empty diagnostics** as proof of no violations
4. **Verify file state** by ensuring it appears in global diagnostics list
5. **Close files when done** to avoid cluttering the global diagnostics response
