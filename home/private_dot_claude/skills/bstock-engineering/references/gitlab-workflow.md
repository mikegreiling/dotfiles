# GitLab Workflow Reference

## GitLab (glab) Configuration

B-Stock's GitLab instance is at `https://gitlab.bstock.io`. All GitLab work goes through the `glab` CLI, which stores its own credential for that host. Prefix commands with `GITLAB_HOST=gitlab.bstock.io` so `glab` targets the B-Stock instance regardless of the current directory. Anything a subcommand doesn't cover is reachable via `GITLAB_HOST=gitlab.bstock.io glab api <endpoint>`.

- Check auth with `GITLAB_HOST=gitlab.bstock.io glab auth status`; re-authenticate with `glab auth login --hostname gitlab.bstock.io`
- On 401/403 errors: re-run `glab auth status` and re-authenticate if the stored credential has expired
- Do not guess the user's username — ask if unknown
- Mike's GitLab username: `mike.greiling` (ID: `421`)

## Pipeline & Job Operations

Use `glab` for CI status and control:

- `GITLAB_HOST=gitlab.bstock.io glab ci list --ref main` — list recent pipelines on a ref
- `GITLAB_HOST=gitlab.bstock.io glab ci get` — detail for a pipeline (defaults to current branch; pass `--pipeline-id <id>` or `--branch <ref>`)
- `GITLAB_HOST=gitlab.bstock.io glab ci retry <job-id>` — retry a failed job

For long waits, use the background poller in `references/pipeline-polling.md` rather than polling inline.

### Merging

`glab mr merge <iid> --squash --remove-source-branch` merges an MR and works against the B-Stock instance.

**Policy:** merge only on Mike's explicit instruction for that MR — do not merge proactively. Once he says to merge, run the `glab` merge (or open the MR in the browser if he prefers to click through), then handle cleanup: verify the merge, pull latest `main`, and delete the local branch.

**Always verify a merge via the API — `glab mr merge` lies.** `glab mr merge <iid> --repo <path> --yes` can print `✓ Merged!` and exit 0 while GitLab silently refuses the merge server-side (observed 2026-07-16 with unmet approval rules: `detailed_merge_status: "not_approved"` — genuine conflicts DO error honestly, approval-gate refusals do NOT). After every merge command, confirm it actually merged: `GITLAB_HOST=gitlab.bstock.io glab api projects/<id>/merge_requests/<iid> | jq -r '.state'` must print `merged`. Before attempting a merge, check readiness with `... | jq '{detailed_merge_status, has_conflicts}'` — and remember that pushing new commits to an MR branch can reset its existing approvals to zero.

## MR Creation — Load the Skill First

**Always load the `bstock-merge-requests` skill before running `glab mr create`.** The skill provides B-Stock-specific guidance on title formatting, Jira integration, template retrieval, checklist validation, and assignee configuration.

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

When creating MRs with `glab mr create`, always include these flags:

```bash
GITLAB_HOST=gitlab.bstock.io glab mr create \
  -t "<title>" -d "<body>" \
  --assignee mike.greiling \
  --remove-source-branch --squash-before-merge \
  --target-branch main --yes
```

## MR Assignee

Always assign MRs to the creator via `--assignee mike.greiling`. There is no user-ID lookup dance — pass the username directly. (Mike's GitLab username is `mike.greiling`, ID `421`.)

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

Check if an MR already exists (the `git push` response will indicate this). If not, load the `bstock-merge-requests` skill first, then run `glab mr create` with the B-Stock conventions the skill provides.

## Sub-Agent Preflight Verification

Before running parallel Task tool operations that use GitLab or Atlassian:

1. Verify GitLab: `GITLAB_HOST=gitlab.bstock.io glab auth status`
2. Verify Atlassian: `mcp__atlassian__getVisibleJiraProjects`
3. If GitLab is unauthenticated: re-authenticate with `glab auth login --hostname gitlab.bstock.io`. If Atlassian is unavailable: STOP and prompt the user to run `/mcp`.

## Jira/GitLab Integration

Every pushed branch should have:
1. A corresponding GitLab MR
2. At least one associated Jira ticket in the MR title

When creating an MR, suggest the Jira ticket based on the current sprint. If no ticket matches, offer to create one in Foundations Pod (FP project). Ask for verification before creating a new ticket.

When a MR is ready for code review, transition the associated Jira ticket to "Technical Review" (transition id: 21 "Merge Request").
