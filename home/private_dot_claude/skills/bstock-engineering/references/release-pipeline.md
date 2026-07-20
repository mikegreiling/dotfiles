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
2. Update `CHANGELOG.md` — in new-style repos it injects the entry extracted from the MR description; in old-style repos it replaces `{VERSION_DATE}` tokens with the actual version and date
3. Create a commit with message: `chore(release): X.Y.Z`
4. Create and push a new git tag for the release
5. Push changes back to `main` branch

### Pipeline 2 — Package Publication

A second pipeline triggers automatically after the version bump commit. The `publish-package` job:

1. Builds and publishes the new package version to B-Stock's npm registry
2. Makes the new version available for portal projects to consume

## Monitoring Package Releases with glab

```bash
# 1. List recent pipelines on main branch (run inside the repo, or use the api form)
GITLAB_HOST=gitlab.bstock.io glab ci list --ref main --per-page 5
# api equivalent (keys off numeric project id): glab api "projects/PROJECT_ID/pipelines?ref=main&per_page=5"

# 2. Find the version bump pipeline — look for bump_version job
GITLAB_HOST=gitlab.bstock.io glab api "projects/PROJECT_ID/pipelines/PIPELINE_ID/jobs"
# Look for: stage: "version", name: "bump_version", status: "success"

# 3. Find the publishing pipeline — look for chore(release) commit
# commit.title format: "chore(release): X.Y.Z" by semantic-release-bot

# 4. Verify publish-package job
GITLAB_HOST=gitlab.bstock.io glab api "projects/PROJECT_ID/pipelines/PUBLISH_PIPELINE_ID/jobs"
# Look for: stage: "build", name: "publish-package", status: "success"
```

**Key pipeline identifiers:**
- Version bump pipeline: contains `bump_version` job in "version" stage
- Publishing pipeline: contains `publish-package` job in "build" stage
- Release commit title: `chore(release): X.Y.Z` authored by `semantic-release-bot`

**Common projects to monitor:**
- `fe-core` — project_id: `506`
- `bstock-eslint-config` — project_id: `525`

## Changelog Requirements

`CHANGELOG.md` is owned by semantic-release — **never edit it manually**, and never edit the package.json `version` field.

| MR Prefix | Changelog Entry Required? |
|-----------|--------------------------|
| `MAJOR:` / `MINOR:` | **Required** — the `check-release-level` CI job fails without it |
| `PATCH:` / `NO-RELEASE:` | Optional |

How the entry is supplied depends on the repo's style — check for `ENABLE_CHANGELOG_EXTRACTION: '1'` in the repo's `.gitlab-ci.yml`:

### New style — MR-description extraction (`ENABLE_CHANGELOG_EXTRACTION: '1'`)

Used by `fe-core`, `bstock-eslint-config`, and most actively maintained repos. The changelog entry lives in the **MR description**, inside a `<details open>…</details>` block (blank line before and after the content, which starts with `### Breaking` or `### Nonbreaking`). CI extracts it at release time and injects it into `CHANGELOG.md` — the MR diff must NOT touch `CHANGELOG.md` at all. Use the repo's MR templates in `.gitlab/merge_request_templates/`; the `bstock-merge-requests` skill covers the block format in detail.

### Old style — in-file entry (variable absent)

The MR itself adds an entry to `CHANGELOG.md` under a `## {VERSION_DATE}` heading:

```markdown
## {VERSION_DATE}
### [Breaking|Nonbreaking]
- [TICKET-ID](https://bstock.atlassian.net/browse/TICKET-ID) Brief description of changes
```

The `{VERSION_DATE}` token is replaced by semantic-release after merge; CI rejects entries containing hard-coded version numbers.

When creating a `MAJOR` or `MINOR` MR, verify the entry exists in the right place for the repo's style. If not, warn the user — the CI pipeline will fail.
