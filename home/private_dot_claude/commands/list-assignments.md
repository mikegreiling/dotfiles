---
argument-hint: [force|refresh|refetch]
description: Generate an epic-grouped summary of current Jira assignments with 48-hour caching
---

Please use the Atlassian Jira MCP tools to generate a summary of my current
assignments, grouped by epic.

> **Workflow note:** The Foundations Pod no longer runs two-week sprints. Work is
> a kanban board of **epics assigned directly to me**, with child stories grouped
> under their parent epic. There is no active-sprint concept — do not query sprints.

## Caching Behavior

- **Cache Duration**: Assignment data is cached for 48 hours in `~/.claude/caches/bstock-assignments-cache.md`
- **Cache Override**: Pass `force`, `refresh`, or `refetch` as `$ARGUMENTS` to bypass cache and fetch fresh data
- **Cache Display**: When using cached data, show the timestamp of when the data was last fetched

## Implementation Steps

1. **Check Cache First**:
   - Read `~/.claude/caches/bstock-assignments-cache.md`.
   - If `$ARGUMENTS` contains `force`, `refresh`, or `refetch`, skip the cache and fetch fresh.
   - If the cache exists and is <48 hours old, display the cached results with their timestamp.
   - If stale (>48h) or missing, fetch fresh (steps below) and rewrite the cache.

2. **Fetch active epics** assigned to me:
   `assignee = currentUser() AND issuetype = Epic AND statusCategory != Done ORDER BY status ASC`
   Fields: ["summary","status","issuetype","priority","assignee","customfield_10049"].
   Collect their keys → EPIC_KEYS.

3. **Fetch children of my epics**: `parent IN (EPIC_KEYS)` — ALL children regardless of
   assignee or status (completed children are shown under active epics).
   Fields: ["summary","status","issuetype","assignee","customfield_10049","parent"].

4. **Fetch my active non-epic issues**:
   `assignee = currentUser() AND issuetype != Epic AND statusCategory != Done ORDER BY updated DESC`
   Bucket each by `fields.parent.key`:
   - parent ∈ EPIC_KEYS → already listed under step 3.
   - parent ∉ EPIC_KEYS → note the parent key; fetch those epics' summary/status/assignee by key and render them under a header labeled "Not assigned to me", listing only my stories beneath.
   - no parent → **orphaned stories**.

5. **Fetch recently completed (light detail, last 30 days)**:
   - Epics: `assignee = currentUser() AND issuetype = Epic AND statusCategory = Done AND resolved >= -30d`
   - Orphaned stories: `assignee = currentUser() AND issuetype != Epic AND parent IS EMPTY AND statusCategory = Done AND resolved >= -30d`
   - Optionally list completed epics' children via `parent IN (...)` (key/summary/status only).

6. **Rewrite the cache** `~/.claude/caches/bstock-assignments-cache.md` with the rendered
   snapshot and a fresh ISO timestamp.

7. **Present the summary**:
   - Start with the data-source indicator:
     - Cached: "📋 **Cached Results** (last updated: [timestamp], [age] ago)"
     - Fresh: "🔄 **Fresh Results** (fetched at [current timestamp])"
   - **Active** section:
     - Each of my epics: `KEY — summary (Status) — N pts`, then its child stories as bullets:
       `* KEY — summary (Status) — N pts`. Annotate a child `[not mine: <displayName>]` or
       `[unassigned]` when its assignee ≠ me.
     - Epics not assigned to me but with my children: header `KEY — summary — Not assigned to me`,
       then only my child stories beneath.
     - `### Orphaned stories (assigned to me, no epic)`: flat bullet list with status (+ pts if any).
   - **Recently Completed (last 30 days — light detail)**: completed epics (with a light child list)
     and completed orphaned stories, flat, status only.
   - Omit story points when unavailable. Order active epics by status progression.

## API Response Size Management

`searchJiraIssuesUsingJql` truncates large responses to a file. To stay inline:

1. Use small `maxResults` and the minimal field sets above.
2. When a response is saved to a file, extract with `jq` — never `Read` the raw JSON into context:
   `jq -c '.issues.nodes[] | {key, summary:.fields.summary, status:.fields.status.name, type:.fields.issuetype.name, parent:.fields.parent.key, assignee:.fields.assignee.displayName, pts:.fields.customfield_10049}' <file>`
3. Cloud ID: `8fd1c100-2018-43ac-bdc1-ca69369799c3`. My accountId (fallback / for assignee checks):
   `712020:102e13ca-76c4-4a0c-89e1-c9fc45369c5d`.
4. Child→epic linkage: `fields.parent.key` (primary), `customfield_10013` (redundant alias).

## Notes

- No sprint queries. If a future workflow reintroduces sprints, revisit this command.
- `statusCategory != Done` / `= Done` is used (rather than enumerating status names) so the
  command is robust to B-Stock's status catalog (To Do / In Progress / Done categories).
