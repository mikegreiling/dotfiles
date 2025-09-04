---
argument-hint: [force|refresh|refetch]
description: Generate summary of current Jira assignments with 48-hour caching
---

Please use the Atlassian Jira MCP tools to generate a summary of my current
assignments.

## Caching Behavior

- **Cache Duration**: Assignment data is cached for 48 hours in `~/.claude/caches/bstock-current-sprint-cache.md`
- **Cache Override**: Pass `force`, `refresh`, or `refetch` as `$ARGUMENTS` to bypass cache and fetch fresh data
- **Cache Display**: When using cached data, show the timestamp of when data was last fetched

## Implementation Steps

To accomplish this task, Claude should:

1. **Check Cache First**:
   - Read `~/.claude/caches/bstock-current-sprint-cache.md` to check for cached assignment data
   - If `$ARGUMENTS` contains `force`, `refresh`, or `refetch`, skip cache and proceed to API calls
   - If cache exists and is less than 48 hours old, display cached results with timestamp
   - If cache is stale (>48 hours) or doesn't exist, proceed to API calls

2. **Identify Active Sprint**: Determine the currently active sprint (if not
   already known). Use today's date to determine whether the sprint in Claude's
   memory is likely to be active.

3. **Update Memory**: If active sprint is not in Claude's memory, or if the
   sprint information in Claude's memory is outdated, update
   `~/.claude/caches/bstock-current-sprint-cache.md` to retain this information (inform
   user of this action and make the change). If the cache file doesn't exist,
   create it.

4. **Get Current Sprint Tickets**: Retrieve ALL tickets/issues assigned to me
   within the currently active sprint (including completed ones)

5. **Get Non-Sprint Tickets**: Retrieve assigned tickets that are NOT part of
   the currently active sprint
   - Use `maxResults` param and filter out "completed" statuses to limit the
     number of tickets returned
   - Sort by `updated` descending to show most recently updated first

6. **Cache Results**: After successful API retrieval, append assignment data to
   `~/.claude/caches/bstock-current-sprint-cache.md` with current timestamp for future
   48-hour cache period

7. **Present Summary**: Display tickets with summaries, prioritized as follows:
   - **ALWAYS start with data source indicator**:
     - For cached results: "📋 **Cached Results** (last updated: [timestamp], [age] ago)"
     - For fresh results: "🔄 **Fresh Results** (fetched at [current timestamp])"
   - Current sprint tickets first (all assigned tickets, including completed)
   - Non-sprint tickets second (maximum 5 active tickets, sorted by last update)
   - For non-sprint tickets, include sprint information: show associated sprint
     name or "Backlog" if no sprint
   - Ordered by priority value (P1 = highest priority, higher P\* values = lower
     priority)
   - Include current "status" for each ticket
   - Show ticket summary/description content
   - Display story points (when available) as "X points" format
   - Show epic link (when available) as "Epic: TICKET-ID" format

### API Response Size Management

When retrieving assignments, Claude should:

1. **Use Pagination**: When searching for non-sprint tickets, use `maxResults`
   to avoid MCP tool response size limits
2. **Filter Irrelevant Items**: For non-sprint tickets only, we can exclude
   tickets with completed status:
   - JQL filter:
     `AND status NOT IN ("Done", "Closed", "Released to Production")`
   - Note: These status values are based on observed API responses and may not
     be exhaustive, prompt user to update this list if necessary.
3. **Sort Non-Sprint Results**: Order by `updated` descending to show most
   recently updated first
4. **Limit Non-Sprint Results**: Show maximum 5 non-sprint tickets (excluding
   completed ones)
5. **Minimal Fields**: Only request essential fields: `["summary", "status",
"issuetype", "priority", "created", "updated", "customfield_10018", "customfield_10013", "customfield_10049"]`
6. **Sprint Information**: Include sprint field (`customfield_10018`) to display
   sprint name or "Backlog" for non-sprint tickets
7. **Story Points & Epic Info**: Include story points (`customfield_10049`) and epic 
   link (`customfield_10013`) in ticket summaries for workload estimation and epic tracking

### Notes on Memory Management

- Sprints can remain open past their end date, but they usually are not. If the
  current sprint in Claude's memory is past its end date, use this as a hint to
  validate these assumptions before proceeding.
- My team's current sprint name, ID, and start/end dates SHOULD BE contained in
  Claude's memory files, sourced from `~/.claude/caches/bstock-current-sprint-cache.md`
- If Claude's memory is outdated or references a closed sprint, update this file
  to include the now-current sprint.
