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

## Epic Sizing & Story-Point Estimation

Sourced from the Engineering (`EN`) Confluence space. A canonical quantitative definition of the T-shirt
sizes **has not been located yet** — one may well exist (a team wiki, the Jira field config, a sizing
rubric) that simply hasn't been found and linked here. If you need the authoritative scale, it's worth
searching for. Until it surfaces, size **relative to peer epics**.

### Epic intake → delivery workflow

Per **Jira Epic Workflow**:

`Open → Needs Requirements (if needed) → Ready for Sizing → T-Shirt Sized → In Shaping → Shaped → In Development → Dev Complete → Quality Review → Release Candidate → Released to Production`

- **Ready for Sizing** — defined enough for dev leads to estimate.
- **T-Shirt Sized** — dev leads assign a rough size (XS / S / M / L / XL) in the **T-Shirt Size** field
  (`customfield_10394`). *Dev leads set this status* — not individual contributors by default.
- **In Shaping / Shaped** — ShapeUp shaping breaks the epic into stories.
- An epic typically only appears on the team **kanban board columns once it reaches In Development**; earlier
  planning statuses live in the board's **Backlog**.

### T-shirt size field

- Field: `customfield_10394` ("T-Shirt Size"), options **XS / S / M / L / XL**.
- Quantitative definition of each size: **not found yet** (see note above) — until located, estimate
  **relative to peer epics**. Observed reference points: `GLOB-3930` (Parcel Phase 1, Backend) = **L**;
  `GLOB-2842` = **M**; `GLOB-4588` (Parcel Phase 1, Frontend) = **M**.

### Story points

- Scale: **Fibonacci** (1, 2, 3, 5, 8, 13, …). Field: `customfield_10049`.
- **Estimate the effort assuming the engineer is NOT using AI assistance** — i.e. how much effort the story
  would take *without* Claude Code / Codex / Cursor. This is a deliberate current policy: points are held to
  a pre-AI baseline so that **velocity** (the term for story points closed per sprint, tracked over time)
  trends upward, and that increase can be attributed to AI tooling. The VP of Engineering uses this signal to
  quantify company-wide productivity gains and justify AI token spend. **Do not deflate an estimate just
  because AI will make the work fast** — size it as the pre-AI effort.
- **The old "split anything over 13 points" rule is relaxed.** Per-sprint point ceilings are now higher, and
  larger **vertical slices** can be taken on as single stories rather than chopped into bite-sized chunks —
  AI lets an engineer carry more in parallel and tackle bigger slices than was practical before adoption. The
  ShapeUp "5–8 points is the sweet spot" note (per **ShapeUp at B-Stock**) is now a historical reference
  point, not a hard cap.
- **QA-handoff threshold** (per **QA Handoffs**): an epic/feature totaling **≥ 25 story points requires a QA
  handoff**; **≤ 24 makes it optional**.

### Reference docs (Confluence → Engineering space)

| Doc | URL |
|-----|-----|
| Jira Epic Workflow | https://bstock.atlassian.net/wiki/spaces/EN/pages/3260448770 |
| Epic Documentation Process (Pre-Development) | https://bstock.atlassian.net/wiki/spaces/EN/pages/3255861267 |
| QA Handoffs | https://bstock.atlassian.net/wiki/spaces/EN/pages/3253043214 |
| ShapeUp at B-Stock | https://bstock.atlassian.net/wiki/spaces/EN/pages/2542567478 |

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

### Issue Links — CAN Be Created via API

Issue links CAN be created programmatically via `mcp__atlassian__createIssueLink` (verified 2026-06-03 — created Relates + Parent-Child links successfully). Common link type IDs:

| Link Type | ID | inward / outward |
|-----------|-----|------------------|
| Relates | `10003` | relates to / relates to |
| Blocks | `10000` | is blocked by / blocks |
| Parent-Child | `10208` | is child of / is parent of |
| Duplicate | `10002` | is duplicated by / duplicates |
| Cloners | `10001` | is cloned by / clones |

For `createIssueLink`, `inwardIssue` takes the subject of the OUTWARD verb (e.g. for Parent-Child, `inwardIssue` = the parent, `outwardIssue` = the child; for Blocks, `inwardIssue` = the blocker).

**Hierarchy caveat:** a Story cannot be a hierarchy `parent` of another Story — the `parent` field only accepts a higher level (Epic). To express "child of" between same-level issues (e.g. a Story under the GLOB-2674 umbrella Story), use a **Parent-Child link**, not the `parent` field.

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
