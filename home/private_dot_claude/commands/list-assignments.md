Please use the Atlassian Jira MCP tools to generate a summary of my current assignments.

Notes:
- My team's current sprint name, ID, and start/end dates SHOULD BE contained in
  Claude's memory files, sourced from `~/.claude/bstock-current-sprint-cache.md`.

To accomplish this task, Claude should:

1. **Identify Active Sprint**: Determine the currently active sprint (if not already known). Use today's date to determine whether the sprint in Claude's memory is likely to be active.
2. **Update Memory**: If active sprint is not in Claude's memory, or if the sprint information in Claude's memory is outdated, update `~/.claude/bstock-current-sprint-cache.md` to retain this information (inform user of this action and make the change). If the cache file doesn't exist, create it with the structure shown below.
3. **Get Current Sprint Tickets**: Retrieve ALL tickets/issues assigned to me within the currently active sprint (including completed ones)
4. **Get Non-Sprint Tickets**: Retrieve assigned tickets that are NOT part of the currently active sprint
   - Use `maxResults` param and filter out "completed" statuses to limit the number of tickets returned
   - Sort by `updated` descending to show most recently updated first
5. **Present Summary**: Display tickets with summaries, prioritized as follows:
   - Current sprint tickets first (all assigned tickets, including completed)
   - Non-sprint tickets second (maximum 5 active tickets, sorted by last updated)
   - For non-sprint tickets, include sprint information: show associated sprint name or "Backlog" if no sprint
   - Ordered by priority value (P1 = highest priority, higher P* values = lower priority)
   - Include current "status" for each ticket
   - Show ticket summary/description content

### API Response Size Management
When retrieving assignments, Claude should:

1. **Use Pagination**: When searching for non-sprint tickets, use `maxResults` to avoid MCP tool response size limits
2. **Filter Irrelevant Items**: For non-sprint tickets only, we can exclude tickets with completed status:
   - JQL filter: `AND status NOT IN ("Done", "Closed", "Released to Production")`
   - Note: These status values are based on observed API responses and may not be exhaustive, prompt user to update this list if necessary.
3. **Sort Non-Sprint Results**: Order by `updated` descending to show most recently updated first
4. **Limit Non-Sprint Results**: Show maximum 5 non-sprint tickets (excluding completed ones)
5. **Minimal Fields**: Only request essential fields: `["summary", "status", "issuetype", "priority", "created", "updated", "customfield_10018"]`
6. **Sprint Information**: Include sprint field (`customfield_10018`) to display sprint name or "Backlog" for non-sprint tickets

## Sprint Cache File Structure

If `~/.claude/bstock-current-sprint-cache.md` needs to be created, use this template:

```markdown
# B-Stock Current Sprint Cache

This file contains current sprint information and assignment cache data for B-Stock Team Sprinters. It is referenced by the main CLAUDE.md file using `@bstock-current-sprint-cache.md`. This file is managed programmatically and excluded from version control.

## Current Sprint Information

- **Active Sprint**: [Sprint Name] (ID: [Sprint ID])
- **Sprint Dates**: [Start Date] - [End Date]

The active sprint will change every two weeks. The `/list-assignments` command will update this information automatically when it detects sprint changes.

## Assignment Cache

*Last updated: [ISO timestamp]*

This section may be used by commands to cache assignment information to reduce API calls and improve performance.
```
