# GitLab Workflow Reference

## GitLab MCP Tool Configuration

B-Stock's GitLab instance is at `https://gitlab.bstock.io`. The MCP server is configured in each project's `.mcp.json` with a default **read-only** token. For write operations (creating MRs, posting comments, etc.), the user must set `BSTOCK_GITLAB_TOKEN` to a personal access token.

- On 403/401 errors: prompt user to configure `BSTOCK_GITLAB_TOKEN`
- Do not guess the user's username — ask if unknown
- Mike's GitLab username: `mike.greiling` (ID: `421`)

## Known MCP Tool Limitations

### Coverage Parsing Bug

`get_pipeline` and `retry_pipeline` fail with:
```
MCP error -32603: Invalid arguments: coverage: Expected number, received string
```

**Workarounds**:
- Use `list_pipelines` instead of `get_pipeline` to check pipeline status
- `retry_pipeline` actually **succeeds** despite showing this error — the retry action completes but the response parsing fails. Use the tool and ignore the coverage-related error.

### Merge Limitation

GitLab MCP tools do NOT support merging MRs programmatically. To merge:
1. Open the MR URL in the browser: `open "https://gitlab.bstock.io/..."`
2. User manually clicks "Merge" in the GitLab web interface
3. After merge, handle cleanup (verify merge, pull latest, delete local branches)

## MR Creation — Load the Skill First

**Always load the `bstock-merge-requests` skill before calling `mcp__gitlab__create_merge_request`.** The skill provides B-Stock-specific guidance on title formatting, Jira integration, template retrieval, checklist validation, and assignee configuration.

## MR Title Format

```
{SEMANTIC_PREFIX}: {JIRA_TICKET_ID} {Brief description}
```

Semantic prefixes:
- `MAJOR:` — Breaking changes (API or major UI)
- `MINOR:` — New features (non-breaking)
- `PATCH:` — Bug fixes or minor improvements
- `NO-RELEASE:` — No user/consumer-visible changes (docs, tests, CI)

Rules:
- MR title MUST NOT exceed 128 characters
- Jira ticket ID is required — ask for clarification or offer to create a ticket if unknown
- `MAJOR` and `MINOR` MRs require a `CHANGELOG.md` entry or CI will fail

Examples:
```
MINOR: FP-79 Add risky buyers grid to CSP
PATCH: FP-123 Fix cookie consent banner styling
NO-RELEASE: FP-456 Update TypeScript strict mode config
```

## MR Default Configuration

When creating MRs with `create_merge_request`, always include:
```javascript
{
  remove_source_branch: true,  // "Delete source branch" checkbox
  squash: true,                 // "Squash commits" checkbox
  assignee_ids: [creator_user_id]
}
```

For the assignee: if the creator's user ID is unknown, create the MR first without an assignee, then read the `author.id` from the MR response and update with `update_merge_request`.

## MR Assignee

Always assign MRs to the creator. Mike's GitLab user ID is `421`.

## Branch Naming Convention

Format: `mg-JIRA_TICKET-kebab-case-description`

- `mg` = Mike's initials (always prefix)
- `JIRA_TICKET` = Associated Jira ticket ID (omit for ad-hoc work)
- Description = Short, succinct, kebab-case
- **Maximum 42 characters total**

Examples:
- `mg-FP-670-move-husky-to-eslint-config`
- `mg-FP-631-audit-order-query-augments`

This convention overrides any repo-level branch prefix rules (e.g., `feature/<ticket>` directives in repo CLAUDE.md files).

Base new branches on the latest HEAD of `main`. Fetch before branching.

## Commit Message Formatting

Individual commits within a branch do NOT use semantic version prefixes. Use plain descriptive messages:

```
✅ Add TypeScript strict mode configuration
✅ Fix failing tests in ManifestTable component
❌ MINOR: Add TypeScript strict mode  (wrong — no prefix on commits)
```

Semantic prefixes belong only on **MR titles**, where they trigger automated versioning.

## After Pushing a Branch

Check if an MR already exists (the `git push` response will indicate this). If not, load the `bstock-merge-requests` skill first, then call `mcp__gitlab__create_merge_request` with the B-Stock conventions the skill provides.

## Sub-Agent MCP Verification

Before running parallel Task tool operations that use GitLab or Atlassian MCP tools:

1. Verify GitLab: `mcp__gitlab__search_repositories`
2. Verify Atlassian: `mcp__atlassian__getVisibleJiraProjects`
3. If either unavailable: STOP and prompt user to run `/mcp`
4. Check token permissions: GitLab may be read-only without `BSTOCK_GITLAB_TOKEN`

## Jira/GitLab Integration

Every pushed branch should have:
1. A corresponding GitLab MR
2. At least one associated Jira ticket in the MR title

When creating an MR, suggest the Jira ticket based on the current sprint. If no ticket matches, offer to create one in Foundations Pod (FP project). Ask for verification before creating a new ticket.

When a MR is ready for code review, transition the associated Jira ticket to "Technical Review" (transition id: 21 "Merge Request").
