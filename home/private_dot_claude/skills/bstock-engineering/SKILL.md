---
name: B-Stock Engineering
description: This skill should be used when working on any B-Stock engineering task, including "create a merge request", "create MR", "push a branch", "create a branch", "check pipeline status", "monitor a release", "package release", "update changelog", "create a Jira ticket", "transition a ticket", "move ticket to done", "mark ticket as complete", "create a story", "assign a ticket", "look up swagger", "API docs", "api-client", "microservice API", "B-Stock workflow", or any task involving GitLab, Jira, or B-Stock projects. Always load this skill when working in the bstock-projects directory.
version: 0.1.0
---

# B-Stock Engineering

This skill provides comprehensive guidance for B-Stock engineering workflows including GitLab operations, Jira ticket management, microservice API documentation, and release pipeline processes.

## B-Stock Ecosystem Overview

B-Stock uses microservices + frontend portals deployed to four environments:

- `bstock-dev.com` — auto-deployed after merging to `main`
- `bstock-qa.com`, `bstock-staging.com` — manual deployment
- `bstock.com` — production

Dev/QA environments require VPN access. The GitLab instance is at `https://gitlab.bstock.io`.

## Mike's Projects

"My projects" refers to these six:

| Project | Type | Notes |
|---------|------|-------|
| `accounts-portal` | Vite portal | `/acct/*` URLs |
| `cs-portal` | Next.js portal | `/csportal/*` URLs |
| `seller-portal` | Next.js portal | `/seller/*` URLs |
| `home-portal` | Next.js portal | `/`, `/all-auctions/*`, `/buy/*` |
| `cops-portal` | Next.js portal | `/cops/*` URLs (Client Operations) |
| `fe-core` | npm package | Shared component + utility library |

Supporting libraries: `fe-scripts`, `bstock-eslint-config`

## Key Stable IDs (Quick Reference)

### GitLab

| Project | ID |
|---------|-----|
| `fe-core` | `506` |
| `bstock-eslint-config` | `525` |

Full service project ID mapping (19 services) → see `references/project-ids.md`

### User Identities

- **GitLab username**: `mike.greiling` (ID: `421`) — B-Stock GitLab instance only
- **Atlassian user ID**: `712020:102e13ca-76c4-4a0c-89e1-c9fc45369c5d`
- **Atlassian cloud ID**: `8fd1c100-2018-43ac-bdc1-ca69369799c3`
- **Atlassian instance**: `https://bstock.atlassian.net`

### Jira

| Project | Key | ID | Board |
|---------|-----|----|-------|
| Foundations Pod (primary team) | `FP` | `10200` | `316` |
| Team Sprinters (former) | `SPR` | `10059` | `59` |

**Jira custom fields**: Story Points: `customfield_10049` · Sprint: `customfield_10018` · Epic Link: `customfield_10013`

## Important Cross-Workflow Rules

- B-Stock uses **Jira** (not GitLab Issues) for ticket tracking. Never use GitLab MCP tools for issue/ticket/story operations.
- Every feature branch pushed to GitLab should have a corresponding MR.
- Every MR should be associated with at least one Jira ticket.
- Use `"ticket"`, `"issue"`, and `"story"` interchangeably — they all mean Jira tickets.
- Always use the `gitlab-mr-creator` agent (not `mcp__gitlab__create_merge_request` directly) when creating MRs.

## Sprint Assignments

To get current sprint assignments, read `~/.claude/caches/bstock-current-sprint-cache.md`. This file is managed by the `/list-assignments` command, which can refresh it with current data.

## Workflow Reference Files

Load the appropriate reference file when performing these tasks:

| Task | Reference File |
|------|---------------|
| GitLab MR creation, branch naming, pipeline ops, MCP quirks | `references/gitlab-workflow.md` |
| Jira ticket creation, status transitions, QA workflow | `references/jira-workflow.md` |
| Package versioning, release pipeline, changelog | `references/release-pipeline.md` |
| Swagger docs, microservice API lookup | `references/api-docs.md` |
| All stable project IDs and cached values | `references/project-ids.md` |

## MCP Tool Requirements

Before any workflow involving GitLab or Atlassian MCP tools:

- Verify GitLab MCP tools are available (check for `mcp__gitlab__search_repositories`)
- Verify Atlassian MCP tools are available (check for `mcp__atlassian__getVisibleJiraProjects`)
- If unavailable: STOP and prompt user to run `/mcp` to authenticate
- Never fall back to curl, `glab`, or manual alternatives

If a GitLab tool call returns 403/401, prompt the user to set `BSTOCK_GITLAB_TOKEN` environment variable with a personal access token.

## Jira API Response Optimization

When using `mcp__atlassian__getJiraIssue`, always include the `fields` parameter to prevent context window bloat (responses can exceed 40,000 tokens without it):

```javascript
mcp__atlassian__getJiraIssue({
  issueIdOrKey: "FP-123",
  fields: ["summary", "status", "created", "updated", "description", "assignee"]
})
```

## Working Rules

- Always `cd` into project directories — never use `git -C /path` or similar flag-based approaches
- Run `npm ci` after creating new branches or when encountering unexplained failures that could be caused by outdated or missing dependencies
- **NEVER run build commands** (`npm run build`, `npm run build:prod`) — CI/CD handles builds


## Additional Resources

### Reference Files

For detailed workflow guidance, load:

- **`references/gitlab-workflow.md`** — GitLab MCP configuration, MR conventions, branch naming, commit formatting, MCP tool quirks and workarounds
- **`references/jira-workflow.md`** — Jira ticket transitions, QA workflow logic, ticket creation guidelines, API limitations
- **`references/release-pipeline.md`** — Package version management, automated release pipeline, changelog requirements
- **`references/api-docs.md`** — Swagger documentation retrieval, service-to-project-ID mapping
- **`references/project-ids.md`** — Complete stable ID cache: all GitLab project IDs, Atlassian IDs, Jira field IDs
