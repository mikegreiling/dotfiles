# Release Pipeline Reference

## Package Version Management

**NEVER manually update the `"version"` key in `package.json`.**

- The project version is managed automatically by CI/CD via `semantic-release`
- Manual version updates cause CI failures and deployment issues
- Version bumps are triggered by semantic version prefixes in MR titles
- This restriction applies ONLY to the project's own `"version"` field
- Updating dependency versions in `"dependencies"`, `"devDependencies"`, `"peerDependencies"` is fine

## Automated Release Pipeline Process

When a feature branch with a semantic version prefix (`MAJOR:`, `MINOR:`, `PATCH:`) is merged into `main`, the following pipeline sequence runs automatically:

### Pipeline 1 — Version Bump

The `bump_version` job runs in the "version" stage after lint, test, and build jobs pass. It uses `semantic-release` to:

1. Update `package.json` and `package-lock.json` version numbers
2. Replace `{VERSION_DATE}` tokens in `CHANGELOG.md` with actual version and date
3. Create a commit with message: `chore(release): X.Y.Z`
4. Create and push a new git tag for the release
5. Push changes back to `main` branch

### Pipeline 2 — Package Publication

A second pipeline triggers automatically after the version bump commit. The `publish-package` job:

1. Builds and publishes the new package version to B-Stock's npm registry
2. Makes the new version available for portal projects to consume

## Monitoring Package Releases with GitLab MCP Tools

```javascript
// 1. List recent pipelines on main branch
mcp__gitlab__list_pipelines({ project_id: "PROJECT_ID", ref: "main", per_page: 5 })

// 2. Find the version bump pipeline — look for bump_version job
mcp__gitlab__list_pipeline_jobs({ project_id: "PROJECT_ID", pipeline_id: "PIPELINE_ID" })
// Look for: stage: "version", name: "bump_version", status: "success"

// 3. Find the publishing pipeline — look for chore(release) commit
// commit.title format: "chore(release): X.Y.Z" by semantic-release-bot

// 4. Verify publish-package job
mcp__gitlab__list_pipeline_jobs({ project_id: "PROJECT_ID", pipeline_id: "PUBLISH_PIPELINE_ID" })
// Look for: stage: "build", name: "publish-package", status: "success"
```

**Key pipeline identifiers:**
- Version bump pipeline: contains `bump_version` job in "version" stage
- Publishing pipeline: contains `publish-package` job in "build" stage
- Release commit title: `chore(release): X.Y.Z` authored by `semantic-release-bot`

**Common projects to monitor:**
- `fe-core` — project_id: `506`
- `bstock-eslint-config` — project_id: `525`

## Changelog Requirements

Most B-Stock projects have a `CHANGELOG.md` at the repo root.

| MR Prefix | Changelog Entry Required? |
|-----------|--------------------------|
| `MAJOR:` | **Required** — CI will fail without it |
| `MINOR:` | **Required** — CI will fail without it |
| `PATCH:` | Optional |
| `NO-RELEASE:` | Optional |

### CHANGELOG.md Entry Format

```markdown
## {VERSION_DATE}
### [Breaking|Nonbreaking]
- [TICKET-ID](https://bstock.atlassian.net/browse/TICKET-ID) Brief description of changes
  - Detailed bullet point 1
  - Detailed bullet point 2 (if needed)
```

The `{VERSION_DATE}` token is replaced with the actual version number and date by the CI pipeline after merge.

When creating a `MAJOR` or `MINOR` MR, verify that a `CHANGELOG.md` entry exists. If not, warn the user — the CI pipeline will fail.
