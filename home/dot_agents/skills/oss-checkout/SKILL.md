---
name: oss-checkout
description: When researching, answering questions about, or validating claims against an open-source or source-available project (a library, framework, tool, or dependency), clone the repo locally into a scratch directory and explore it with local tools instead of fetching individual files through the GitHub/GitLab API or raw-file URLs. Use whenever answering would require reading more than one or two files of an external project's source.
version: 0.0.0-dev
---

# OSS Checkout

When the user wants to research an external open-source (or source-available) project — how something is implemented, whether a claim about its behavior is true, where a bug lives, how an API actually works under the hood — **clone the repository locally and explore it there**. Do not page through the codebase remotely via `gh api`, `glab api`, raw.githubusercontent.com URLs, WebFetch, or per-file API reads: that burns a slow round-trip per file, defeats grep/glob, and makes it impossible to run or test anything.

## Where clones go

All research checkouts live in one scratch directory:

```
/Volumes/Workspace/Projects/oss-checkouts/<repo-name>
```

- **Check for an existing checkout first.** If the repo is already there, `git fetch` (or `git pull` on the default branch) instead of re-cloning.
- Everything in this directory is **disposable**: never do original work there, never commit or push, and feel free to delete or re-clone at will. The user's real projects live elsewhere — do not confuse the two.

## How to clone

Default to a shallow clone — it's fast even for large repos:

```bash
git clone --depth 1 <url> /Volumes/Workspace/Projects/oss-checkouts/<repo-name>
```

Adjust when the task needs more:

- **Git archaeology** (blame, when-did-this-change, bisect): clone with full history, or run `git fetch --unshallow` on an existing shallow checkout.
- **A specific version matters** (e.g. validating the behavior of a dependency the user actually runs): find the installed version (lockfile, `package.json`, etc.) and check out the matching tag — `git clone --depth 1 --branch v1.2.3 <url> …`. Don't validate claims about v1.2.3 against `main`.
- **Very large repos / monorepos**: `--filter=blob:none` (blobless clone) keeps it cheap while still allowing full-tree checkout and history operations.

## After cloning

Explore with normal local tools — Grep/Glob/Read, run the test suite, write a scratch script to test an assumption. That's the whole point: cheap, fast, verifiable exploration instead of API round-trips.

## When NOT to clone

- A single quick fact that official docs, a changelog, or one README answers — a targeted WebFetch is fine.
- The project is an installed dependency and the question is about its *published* output — the copy in `node_modules` may already answer it (but note it lacks tests, history, and often the original source).
