# Claude Code User Memory

My name is "Mike Greiling" (prefer "Mike"). Professional software engineer with a background
in TypeScript, React, and NextJS. Presume competence. Treat all prompts as though I appended
"correct me if I'm wrong" — push back if I'm incorrect.

## Core Behavior

- Notice when workflows could use fewer prompts/tool calls; suggest caching stable values in memory files
- Document API quirks and cache stable values in appropriate CLAUDE.md/skill files
- Open URLs in the default browser using macOS `open "https://..."` command; always offer this for Jira tickets, GitLab MRs, etc.
- **Never use hard line breaks in markdown documents** — do not wrap prose at ~80 characters. Markdown renderers handle reflowing; hard wraps make terminal output truncated and unreadable at full width.

## Bash Quirks

- If `cd` is blocked with "was blocked", use `List(/path/to/directory)` to add it to the session whitelist, then retry
- `cd` state **persists** between separate Bash tool calls — never cd into the same directory twice in a sequence
- If a commit fails with `gpg: signing failed: No pinentry`, check that `pinentry-mac` is installed via homebrew

## Package Management

- **NEVER delete lock files** (package-lock.json, yarn.lock, composer.lock, etc.) — EVER
- To resolve lock file conflicts: `git checkout HEAD package-lock.json` or `npm install`
- This applies to ALL package managers: npm, yarn, composer, bundler, pip, etc.

## Git Safety

- Never commit to default branches (`main` or `master`) — always use feature branches
- If asked to commit while on a default branch, suggest creating or switching to a feature branch first
- **ALWAYS use `--force-with-lease`** instead of `--force` for git pushes
- After creating a new branch, run the appropriate dependency install command (`npm ci`, `composer install`, etc.)
- When encountering unexplained lint/type/build failures, try `npm ci` (or equivalent) first before investigating code

## MCP Tool Availability

- If Atlassian or GitLab MCP tools are unavailable: **STOP** and prompt user to run `/mcp` to authenticate
- Never fall back to `curl`, CLI tools (`gh`, `glab`), or manual alternatives for MCP-dependent operations
