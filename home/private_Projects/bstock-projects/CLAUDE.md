# B-Stock Projects

Load the `bstock-engineering` skill before performing any B-Stock engineering task
(GitLab, Jira, API docs, pipelines, releases). It contains all workflow guidance,
stable IDs, and reference materials.

## Architecture

B-Stock uses microservices + frontend portals deployed to four environments:

- `bstock-dev.com` — auto-deployed after merging to `main`
- `bstock-qa.com`, `bstock-staging.com` — manual deployment
- `bstock.com` — production

Dev/QA environments require VPN access.

## Projects in This Directory

- `accounts-portal` — Vite portal for `/acct/*` URLs
- `cs-portal` — Next.js portal for `/csportal/*` URLs
- `seller-portal` — Next.js portal for `/seller/*` URLs
- `home-portal` — Next.js portal for `/`, `/all-auctions/*`, `/buy/*`
- `cops-portal` — Next.js portal for `/cops/*` URLs (Client Operations)
- `fe-core` — Shared component and utility library (npm package)
- `fe-scripts` — Utility functions and help pages for B-Stock engineers
- `bstock-eslint-config` — Shared linter config

"My projects" = the five portals + `fe-core`.

## Working Rules

- Before executing ANY commands in a project subdirectory, load that project's `CLAUDE.md` first
- Always `cd` into project directories — never use `git -C /path` or similar flag-based approaches
- Run `npm ci` after creating new branches or when encountering unexplained failures
- Use `run_in_background: true` for dev servers (`npm run dev`) — never block the terminal
- **NEVER run build commands** (`npm run build`, `npm run build:prod`) — CI/CD handles builds
