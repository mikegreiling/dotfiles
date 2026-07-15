# Claude Code User Memory

My name is "Mike Greiling" (prefer "Mike"). Professional software engineer with a background
in TypeScript, React, and NextJS. Presume competence. Treat all prompts as though I appended
"correct me if I'm wrong" — push back if I'm incorrect.

## Core Behavior

- Notice when workflows could use fewer prompts/tool calls; suggest caching stable values in memory files
- Document API quirks and cache stable values in appropriate CLAUDE.md/skill files
- Open URLs in the default browser using macOS `open "https://..."` command; always offer this for Jira tickets, GitLab MRs, etc.
- **Never use hard line breaks in markdown documents** — do not wrap prose at ~80 characters. Markdown renderers handle reflowing; hard wraps make terminal output truncated and unreadable at full width.

## Model Delegation (token budget)

- I have a weekly cap on Fable 5 tokens. When running as Fable: **delegate execution to cheaper models** (Opus or below, via sub-agents) whenever the task does not require Fable-tier reasoning — implementing an already-settled spec or plan, mechanical refactors, test writing, probe/lab campaigns, doc updates, bulk searches. The delegate only needs to execute faithfully and flag surprises.
- Reserve Fable's own tokens for: design and architecture judgment, ambiguous trade-offs, synthesis of findings, orchestration/review of the delegates, and anything where being wrong is expensive.
- Rule of thumb: if the prompt to a sub-agent can fully specify success, Fable should not do the work itself.
- **Resume caveat (verified 2026-07-15):** resuming a sub-agent via SendMessage does NOT preserve the spawn-time `model` PARAMETER — the resumed instance silently falls back to the session default model (i.e. Fable). Resumed agents may also lose their worktree and land in the primary checkout. **Verified fix:** a model pinned in an agent-type DEFINITION (`.claude/agents/<name>.md` frontmatter `model: opus`) DOES survive message-resume — so delegate via a definition-pinned agent type (e.g. `opus-executor`, created 2026-07-15 in things-api's `.claude/agents/`; replicate the file in other repos as needed) instead of `subagent_type: general-purpose` + `model` param. If a param-pinned agent must be continued, spawn FRESH with the model re-pinned and a recovery brief (branch, worktree path, VM state, prior commits) rather than resuming. To verify what model an agent actually ran: `grep -o '"model":"[^"]*"' <session-tmp>/tasks/<agent-id>.output | sort | uniq -c`.

## Bash Quirks

- If `cd` is blocked with "was blocked", use `List(/path/to/directory)` to add it to the session whitelist, then retry
- `cd` state **persists** between separate Bash tool calls — never cd into the same directory twice in a sequence
- If a commit fails with `gpg: signing failed: No pinentry`, check that `pinentry-mac` is installed via homebrew

## Package Management

- **NEVER delete lock files** (package-lock.json, yarn.lock, composer.lock, etc.) — EVER
- To resolve lock file conflicts: `git checkout HEAD package-lock.json` or `npm install`
- This applies to ALL package managers: npm, yarn, composer, bundler, pip, etc.
- **NEVER use `--legacy-peer-deps` under any circumstances** — it is never the correct solution. It silently drops peer dependencies from the lockfile, breaking installs for other developers and in CI. When a peer conflict arises, fix the root cause: upgrade (or downgrade) the conflicting package to a version with compatible peer declarations.

## Git Safety

- Never commit to default branches (`main` or `master`) — always use feature branches
- If asked to commit while on a default branch, suggest creating or switching to a feature branch first
- **Exception — my dotfiles repo** (`~/.local/share/chezmoi`): I am the sole contributor, so commit directly to `main` there. Do not create feature branches for dotfiles changes; commit (and push when asked) straight to `main`.
- **ALWAYS use `--force-with-lease`** instead of `--force` for git pushes
- After creating a new branch, run the appropriate dependency install command (`npm ci`, `composer install`, etc.)
- When encountering unexplained lint/type/build failures, try `npm ci` (or equivalent) first before investigating code

## Tool Preferences

- Prefer purpose-built tools — `glab`, `gh`, and MCP servers — over hand-rolled HTTP. Raw `curl` against an API endpoint is a **last resort**, used only when no `glab`/`gh`/MCP tool covers the operation.
- `glab`/`gh` are encouraged and often *preferred* over the equivalent MCP server: they keep large responses out of the context window and run well as background tasks (e.g. polling CI). Use whichever fits the job — just don't drop to `curl` when one of them exists.
- If an MCP server you actually need (e.g. Atlassian/Jira, which has no CLI) is unavailable: **STOP** and prompt the user to run `/mcp` to authenticate — don't silently work around it with `curl`.
