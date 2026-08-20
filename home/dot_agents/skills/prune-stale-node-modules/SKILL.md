---
name: prune-stale-node-modules
description: Reclaim disk space by deleting the top-level node_modules directory from git worktrees that have gone untouched for N days. Use whenever the user asks to "prune node_modules", "free up disk space from old worktrees", "clean stale worktrees", "purge vendored dependencies from inactive checkouts", "my workspace volume is full", or otherwise wants abandoned clones and linked worktrees stripped of their installed dependencies without touching source, git history, or anything still in active use. Wraps a standalone bash script that enumerates every worktree under a root directory, scores each one's last activity from git signals, and removes only the stale ones — with a dry-run mode that reports exactly what would go.
version: 1.0.0
---

# Prune Stale node_modules

`node_modules` is the single largest reclaimable thing on a developer's disk, and every abandoned branch worktree carries a full copy. This skill deletes those copies — and *only* those copies — from worktrees that have shown no activity for a configurable number of days. Nothing else is touched: no source files, no git objects, no worktree registration. Re-installing is a single `npm ci` away, so the operation is cheap to undo and safe to run on a schedule.

## Invoking it

```bash
~/.claude/skills/prune-stale-node-modules/scripts/prune-stale-node-modules.sh --dry-run
```

**Always run `--dry-run` first** and show the user the report before running for real. The dry run does zero writes and prints the exact list that a live run would delete.

Then, once the user confirms:

```bash
~/.claude/skills/prune-stale-node-modules/scripts/prune-stale-node-modules.sh
```

## Flags

| Flag | Default | Meaning |
| --- | --- | --- |
| `--days N` | `28` | Inactivity cutoff. A worktree is pruned only if its most recent activity is **more than** N days old. **Bigger N = stricter = fewer deletions.** `--days 0` prunes everything that isn't active this instant; `--days 3650` prunes essentially nothing. |
| `--root PATH` | `/Volumes/Workspace` | Directory tree to scan. |
| `--dry-run` | off | Report what would be deleted; delete nothing. |
| `--linked-only` | off | Consider only linked worktrees (those whose `.git` is a *file*), skipping each repo's primary checkout. Useful when the user wants their main clones left installed and ready. |
| `--max-depth N` | `4` | How many levels below `--root` to search for worktrees. Only needs raising if `--root` points somewhere shallower than usual. |
| `-h`, `--help` | | Usage. |

## What it actually does

1. **Enumerate.** Finds every git working directory under `--root` by looking for a `.git` entry — a *directory* for a primary clone, a *file* for a linked worktree. Descent into `node_modules` and `.git` is pruned for speed. On Mike's machine this finds ~100 worktrees (roughly 70 primary clones, 30 linked) across `/Volumes/Workspace/Projects/*`, including both the `bstock-projects/.worktrees/<name>` convention and the sibling-directory convention (`bstock-projects/auction-glob4949`).
2. **Gate.** For each worktree it considers exactly one path: `<worktree>/node_modules`, and only when `<worktree>/package.json` also exists. Both are hard gates.
3. **Score activity.** Last-activity is the newest of three signals: the HEAD commit time, the mtime of the worktree's own git index (captures staging and general git usage), and the newest mtime among the files `git status` reports as modified or untracked (captures unstaged editing). `node_modules` is deliberately excluded from that last signal — otherwise a repo that doesn't gitignore it would look permanently active because of its install-time mtime.
4. **Prune.** If the worktree is older than the cutoff, `du -sk` the directory and `rm -rf` it. Otherwise record it as kept, with its age.
5. **Report.** Prints a size-sorted table of what was (or would be) deleted, a list of what was kept and how old it is, an anomalies section, and the total space freed. The deleted table is the audit trail — it names every path removed.

## Safety guarantees

- Only ever removes a directory **literally named `node_modules`**, at the **top level** of a worktree that has a `package.json`. Nested `node_modules` are never targeted independently.
- **Never follows symlinks.** A symlinked `node_modules` is reported as an anomaly and left alone, so a shared or pnpm-style store is never followed out of the tree.
- **Fails safe.** If a repo is unreadable, broken, or yields no usable activity signal at all, it is treated as *active* and skipped — with a note in the anomalies section.
- **One bad repo never aborts the sweep.** Per-worktree failures are collected and reported at the end; the exit code is 0 whenever the sweep completed, even if nothing qualified.
- **Read-only with respect to git state.** The script exports `GIT_OPTIONAL_LOCKS=0` so its own `git status` calls cannot refresh and rewrite each index — which would otherwise bump every worktree's index mtime to "now" and make the entire tree look active on the following run.
- Redundant path checks run immediately before every `rm -rf` (name, symlink, directory, and depth-under-root), so a surprising path is refused rather than deleted.

## Running it periodically

This is safe to run on a schedule — monthly, or whenever the workspace volume gets tight. The worst case for a false positive is that the user runs `npm ci` again in a worktree they were about to return to. Nothing unrecoverable is ever removed, and the printed report tells them exactly which worktrees need reinstalling.
