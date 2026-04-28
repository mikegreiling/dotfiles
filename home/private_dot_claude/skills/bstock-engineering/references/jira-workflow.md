# Jira Workflow Reference

## Important Terminology

- "Ticket", "issue", and "story" are used interchangeably — they all mean Jira tickets
- B-Stock does NOT use GitLab issues. All issue/ticket/story operations use Atlassian MCP tools
- Mike's primary team is **Foundations Pod** (`FP` project key)

## Ticket Status Workflow

Applies to projects: `FP`, `SPR`, `MULA`, `TBD`, `ZRO`, `WRH`, `GLOB`
(The `BUGS` project follows completely different statuses)

### Standard Path: To Do → Done

| Step | From | To | Transition Name | ID |
|------|------|-----|----------------|-----|
| 1 | To Do | In Progress | "Start Work" | `11` |
| 2 | In Progress | Technical Review | "Merge Request" | `21` |
| 3 | Technical Review | Merged | "Merge" | `31` |
| 4 | Merged | Quality Review | "Ready for QA" | `41` |
| 5 | Quality Review | Done | "QA BYPASS" | `211` |

Step 2 ("Merge Request") should happen when the GitLab MR is created and ready for review.
Step 3 ("Merge") should happen when ALL associated MRs have been merged or closed.

### QA Workflow Decision Logic

When transitioning to Quality Review (step 4 above):

**If "nontestable" label exists on the ticket:**
→ Use "QA BYPASS" (id: 211) to go directly to Done

**If no "nontestable" label:**
→ Check for "Acceptance Criteria" section in the ticket description
  - If missing: prompt to add QA testing instructions to the description
  - If present: leave in Quality Review for a QA engineer to use "QA PASS"

**Rules:**
- "QA PASS" (id: 51) is for QA engineers only — developers MUST NOT use this
- ALWAYS ask for confirmation before using "QA BYPASS"
- ALWAYS ask to apply "nontestable" label when using "QA BYPASS"

### Alternative Transitions

| Transition | ID | From → To |
|-----------|-----|-----------|
| MR Fail | — | Technical Review/Merged → In Progress |
| Rework | `181` | Done/Quality Review → In Progress |
| QA Block | — | Quality Review → Blocked |
| Stop Work | `111` | In Progress → To Do |
| Work Block | — | In Progress/To Do → Blocked |

### Reverting from Done

| Transition | ID | Destination |
|-----------|-----|------------|
| Rework | `181` | In Progress |
| Reopen | `81` | Reopened |
| QA | `231` | Quality Review |

### Closing a Ticket (Distinct from "Done")

"Closed" = work will NOT be completed. "Done" = work completed successfully. These are completely different statuses.

Path to close:
1. Return ticket to "To Do" (use "Stop Work" id: `111` from In Progress)
2. From "To Do": use "Close" transition (id: `191`)

Common close resolutions: "Won't Do", "Duplicate", "Cannot Reproduce"

## Ticket Creation Guidelines

### Issue Type Default

Always use **Story** (id `10010`), never **Task** (id `10006`). This applies to all B-Stock projects.

### Parent Epic Assignment

Most tickets (outside `BUGS` project) should have a parent epic. Always ask what parent epic a new ticket belongs to before creating.

**Common catch-all epic**: `GLOB-1987` "Optimization Cabal" — use for technical debt, performance improvements, or developer experience work.

**Default project**: When creating tickets not immediately assigned to Mike, use `GLOB` project unless specified otherwise.

### Ticket Title Formatting

Use bracketed tags to indicate affected project(s) or service(s):

| Tag | Meaning |
|-----|---------|
| `[SPIKE]` | Research/prototyping — not QA-testable |
| `[fe-core]` | Frontend core shared library |
| `[AP]` | Accounts Portal |
| `[BP]` | Buyer Portal |
| `[SP]` | Seller Portal |
| `[CSP]` | CS Portal |
| `[HP]` | Home Portal |
| `[FE]` | General frontend work |
| `[Account svc]`, `[Search svc]` | Backend services |
| `[SP/CSP]`, `[FE Portals]` | Multiple projects |

After tags, use descriptive titles with action verbs (Fix, Update, Remove, Audit, etc.):
- `[fe-core] Fix logging context token + trace details`
- `[SP] Update deprecated 'legacyBehavior' Next Link component`
- `[SPIKE] Evaluate parallelized tests through Jira/Vitest sharding in CI`

### Sprint Assignment

To assign a ticket to the current sprint, use `customfield_10018` with a direct number (NOT an array):
```javascript
// ✅ Correct
{ "customfield_10018": 3660 }

// ❌ Wrong
{ "customfield_10018": [3660] }
```

Get the current sprint ID from `~/.claude/caches/bstock-current-sprint-cache.md`.

## Atlassian API Limitations

### Cannot Create Issue Links Programmatically

The "blocks/is blocked by" relationship cannot be set via API. Instruct user to add these manually in Jira UI.

### Story Points on Bug Issue Types

`customfield_10049` (Story Points) cannot be set via API on `Bug` issue types in the `SPR` project:
- Works: Story, Task, Epic
- Fails: Bug (returns "Bad Request")

For Bug tickets, tell user to set story points manually in Jira UI.

### getJiraIssue — Always Use Field Limiting

Jira responses can exceed 40,000 tokens. Always include `fields` parameter:

```javascript
mcp__atlassian__getJiraIssue({
  issueIdOrKey: "FP-123",
  fields: ["summary", "status", "created", "updated", "description", "assignee"]
})
```

### When API Limitations Block a Task

1. Provide manual instructions with specific steps
2. Include resource URLs to relevant Jira interfaces
3. Offer to open URLs using macOS `open` command
4. Document the limitation for future reference

## Common Jira Projects

| Key | Team/Purpose |
|-----|-------------|
| `FP` | Foundations Pod — Mike's primary team |
| `BP` | Buyer Pod |
| `SP` | Seller Pod |
| `SPR` | Team Sprinters — Mike's former team |
| `MULA` | Team MULA |
| `TBD` | Team TBD |
| `ZRO` | Team ZERO |
| `WRH` | Team WRH |
| `GLOB` | 3MP Global |
| `BUGS` | Bug Triage Project (different workflow!) |
