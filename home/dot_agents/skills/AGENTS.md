# ~/.agents/skills — how skills are managed and version-controlled

`~/.agents/skills/` is the single canonical home for Mike's agent skills. Every agent harness (Claude Code, Codex, Cursor, OpenCode, Pi, …) reads skills from here, either natively or via symlinks (e.g. `~/.claude/skills/<name>` → `../../.agents/skills/<name>`). Never create a skill directly under `~/.claude/skills/`; create it here and symlink.

Skills fall into four management tiers. **Before editing any skill, identify its tier** (quickest check: `chezmoi managed | grep '.agents/skills/<name>'` — a hit means tier 1; otherwise `npx -y skills list -g` shows `Source: local` for tiers 3/4 or a repo for tier 2).

## Tier 1 — Local skills, version-controlled by chezmoi (the default for anything hand-written)

Authored by Mike/agents, tracked in the dotfiles repo (`~/.local/share/chezmoi`, source dir `home/dot_agents/skills/<name>/`). The matching `~/.claude/skills/<name>` symlink is also managed (`home/private_dot_claude/skills/symlink_<name>`).

Currently: `atlassian-mcp-shim`, `bstock-demo-video`, `bstock-engineering`, `bstock-merge-requests`, `dotfiles-workflow`, `fastmail`, `slack`, `oss-checkout`, `prune-stale-node-modules`, `record-idea`, `things-cli`.

Rules (see the `dotfiles-workflow` skill for the full chezmoi procedure):

- Edit the **live file** under `~/.agents/skills/` (never the chezmoi source copy), then `chezmoi add ~/.agents/skills/<name>` (re-run after every edit — `chezmoi add` is a snapshot, not a link) and commit in `~/.local/share/chezmoi`. Mike is the sole contributor there: commit straight to `main`.
- **An edit that is not `chezmoi add`ed is not saved.** `chezmoi diff ~/.agents/skills` shows anything drifting; it should be empty when you finish a task that touched a skill. Prompt Mike to commit (or commit when he's asked you to).
- New hand-written skill: create `~/.agents/skills/<name>/SKILL.md`, symlink `ln -s ../../.agents/skills/<name> ~/.claude/skills/<name>`, then `chezmoi add` both the directory and the symlink.

## Tier 2 — Third-party skills installed with Vercel's `skills` CLI (`npx skills`)

Installed with `npx -y skills add <owner/repo> -g` (global → lands here). Their content is **not** in the dotfiles repo; the ledger that records what is installed and from where **is**: `~/.local/state/skills/.skill-lock.json` (chezmoi source `home/private_dot_local/state/skills/dot_skill-lock.json`). The CLI also creates the per-agent symlinks (e.g. into `~/.claude/skills/`) itself; those symlinks are deliberately unmanaged.

Currently: `skill-creator` (anthropics/skills), `bstock-code-review-guidelines` (B-Stock GitLab `three-mp/common/agent-skills`), `context7-cli` + `find-docs` (upstash/context7), `dd-pup` (datadog-labs/agent-skills), `obsidian-cli` + `obsidian-markdown` (kepano/obsidian-skills), and 13 from cloudflare/skills (`agents-sdk`, `cloudflare`, `cloudflare-email-service`, `cloudflare-one`, `cloudflare-one-migrations`, `durable-objects`, `sandbox-migrate-to-next`, `sandbox-next`, `sandbox-stable`, `turnstile-spin`, `web-perf`, `workers-best-practices`, `wrangler`; of these only `web-perf` is exposed to Claude Code).

Rules:

- **Do not hand-edit these** — `npx skills update` will overwrite them and the edit is lost silently. If a third-party skill needs B-Stock/Mike-specific behavior, put it in a tier-1 skill that references the third-party one (the way `bstock-engineering` layers on `slack`).
- Install/remove/update only through the CLI (`npx -y skills add|remove|update -g`), then `chezmoi add ~/.local/state/skills/.skill-lock.json` and commit so a fresh machine can reinstall the same set.
- `npx -y skills list -g` is the authoritative inventory; `Source: local` means the skill is NOT tier 2.

## Tier 3 — Skills whose content lives elsewhere and is symlinked in

Currently: `things-gtd` → `~/Memex/04 - Resources/Agent Skills/things-gtd` (Mike's Obsidian vault, synced by Obsidian, not git). The `~/.agents/skills/things-gtd` symlink and the `~/.claude/skills/things-gtd` symlink are chezmoi-managed; the content is not.

Rules: edit the content in place (through the symlink is fine). Nothing to `chezmoi add` unless the symlink target changes. Don't `chezmoi add` the resolved content — it would freeze a copy that diverges from the vault.

## Tier 4 — Untracked (should be empty)

A skill that is in none of the above is unmanaged and will be lost on a new machine. When you find one, ask Mike which tier it belongs to; the usual answer for hand-written skills is tier 1 (`chezmoi add` it and its symlink). As of 2026-08-20 this tier is empty.

## Maintaining this file

Keep the per-tier inventories above correct: when a skill is added, removed, or moved between tiers, update the list here in the same commit. Verify against `chezmoi managed | grep skills` and `npx -y skills list -g` rather than trusting the lists. This file and its `CLAUDE.md` shell are themselves tier 1 (chezmoi-managed).
