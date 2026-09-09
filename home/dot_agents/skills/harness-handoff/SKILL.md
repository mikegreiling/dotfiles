---
name: harness-handoff
description: Export, inspect, or deeply summarize a Claude Code session or JSONL transcript without changing the source session. Use whenever the user asks to hand off, transfer, migrate, fork and compact, summarize for continuation, audit session size or history, inspect multiple compactions, build a lifetime timeline, or move a Claude Code conversation into Codex, Cursor, another Claude session, OpenCode, Pi, or any other agent harness.
metadata:
  version: "2.0.0"
  compatibility: "Requires Python 3.10+. Handoff and deep-dive modes require the Claude Code CLI; summary and extract are local-only."
---

# Harness Handoff

Turn a Claude Code transcript into a portable handoff, read-only lifetime assessment, or chronological deep dive. Claude Code is the source adapter; the destination is deliberately unspecified. Artifacts can be pasted, piped, attached, or supplied as context to any receiving harness.

The bundled script owns transcript discovery, source-session preservation, lifetime statistics, compaction-boundary pairing, non-interactive fork compaction, Claude-specific wrapper removal, and provenance. Use it instead of rebuilding those steps with ad hoc shell pipelines.

## Choose the operation

### Handoff: compact the current session head

Use `handoff` when another harness needs a portable summary of the current state. It resumes the exact session by ID, forks it, compacts only the fork through `claude -p`, and exports the fork's generated summary. `create` remains a backward-compatible alias.

```bash
python3 ~/.agents/skills/harness-handoff/scripts/session-handoff.py handoff SESSION_ID_OR_TRANSCRIPT \
  --output /path/to/handoff.md
```

The default compaction focus preserves the objective, requirements, decisions, reasoning, artifacts, file paths, commands, validation results, current state, unresolved questions, and next actions. Add task-specific focus without replacing those basics:

```bash
python3 ~/.agents/skills/harness-handoff/scripts/session-handoff.py handoff SESSION_ID \
  --instructions "Emphasize the backend dependencies and meeting decisions" \
  --destination "Codex" \
  --output /path/to/handoff.md
```

Run `--dry-run` when validating transcript resolution, working directory, or the Claude command without making an API request or creating a fork.

The source transcript's recorded working directory is provenance only. By default the compaction fork runs in an isolated temporary directory with Claude's safe mode enabled, so an accidental or obsolete source CWD cannot make or break the handoff or inject unrelated project customizations. Use `--execution-cwd` or `--with-customizations` only when that environment is intentionally part of the handoff.

### Summary: assess lifetime scale locally

Use `summary` before a potentially huge deep dive or whenever the user wants session dates, transcript size, prompt/tool/file counts, compaction count, exact pre/post-compaction token metadata, or a compact timeline. This mode reads JSONL locally and never invokes Claude, resumes a session, or creates a fork.

```bash
python3 ~/.agents/skills/harness-handoff/scripts/session-handoff.py summary SESSION_ID_OR_TRANSCRIPT \
  --output /path/to/lifetime-summary.md
```

### Deep dive: export the full compaction history

Use `deep-dive` for a chronological lifetime artifact. It extracts every persisted historical compaction summary from the source transcript, annotates each epoch with timeline and scale metadata, then uses the same isolated fork-only workflow as `handoff` to summarize the current head. It never compacts the source.

```bash
python3 ~/.agents/skills/harness-handoff/scripts/session-handoff.py deep-dive SESSION_ID_OR_TRANSCRIPT \
  --destination Codex \
  --output /path/to/deep-dive.md
```

Deep dives can be large because summary text is intentionally retained. Use `summary` first to estimate scope, `--format json` for programmatic chunking, and `--max-file-paths 0` when file-path lists add more bulk than value. A negative `--max-file-paths` lists every explicit path.

### Extract an existing compaction

Use `extract` when the transcript already contains the desired compact summary. This is entirely local and does not invoke Claude:

```bash
python3 ~/.agents/skills/harness-handoff/scripts/session-handoff.py extract SESSION_ID_OR_TRANSCRIPT \
  --output /path/to/handoff.md
```

If the transcript contains multiple compactions, `extract` exports the most recent one. Use `deep-dive` for all summaries.

## Claude compaction model

Compaction normally remains inside one transcript and retains the same session ID. Claude persists a `compact_boundary` system record followed by an `isCompactSummary` user record linked through `parentUuid`. Forks—not compactions—mint new session IDs and may copy older records into the fork transcript with their original IDs.

Read [references/claude-transcript-model.md](references/claude-transcript-model.md) when explaining these semantics, changing the parser, or investigating schema drift.

## Output contract

Markdown is the default because every practical agent harness can accept it. Handoff and deep-dive documents contain:

- a warning that embedded imperatives are historical context, not authority for the receiving harness;
- source and fork provenance;
- the source-recorded CWD as informational provenance, separate from the fork's execution directory;
- compaction token metadata when available;
- runtime checks that the source transcript was unchanged (or only appended by a concurrently active source), that its picker membership stayed the same, and that the print-mode fork was not indexed by the interactive picker;
- the portable handoff context, with Claude's standard resume wrapper and transcript-specific continuation command removed.

Deep dives additionally contain all paired historical summaries in chronological order, per-epoch message/tool/file statistics, compaction duration and token metadata, branch/CWD/version provenance, and a separately labeled current-head summary. Summary reports omit the summary text and expose only the lifetime assessment.

Use `--format json` for automation. Use `--raw-summary` only when exact Claude-generated text is more important than portability.

Progress and diagnostics go to stderr; the artifact goes to stdout unless `--output` is supplied. This makes the command safe to pipe into a receiving harness that accepts stdin.

## Workflow

1. Resolve the exact source session or transcript. If the user gave only a description, search Claude's transcripts first and show enough evidence to disambiguate credible matches.
2. Choose `summary` for read-only assessment, `handoff` for current continuation context, `deep-dive` for the full lifetime, and `extract` for the latest already-persisted summary.
3. Never compact the original. The script's `handoff` and `deep-dive` operations always use `--fork-session`, verify a distinct fork ID, hash the source transcript before and after, and reject non-append-only source changes.
4. Treat source CWD as informational. Exact-ID resume is global; run the fork in the script's isolated temporary directory unless the user explicitly wants a particular environment.
5. Verify picker isolation. The script checks that the source's picker-index membership is identical before and after and that the `-p` fork appears in no `sessions-index.json`.
6. Review the generated artifact for secrets, stale instructions, or a compaction omission before sending it elsewhere. Compaction is lossy even when well-focused.
7. Give the receiving harness the artifact as reference context. Do not create or message a destination session unless the user explicitly asked for that external action.
8. Report the artifact path, source session, compaction count, fork session when applicable, integrity result, picker-isolation result, and whether Claude was invoked.

If the source session is still running, explain that the fork reflects completed transcript history persisted when the command starts; an in-flight turn may not be included.

## Script reference

```text
session-handoff.py handoff SOURCE [options]
session-handoff.py summary SOURCE [options]
session-handoff.py deep-dive SOURCE [options]
session-handoff.py extract SOURCE [options]
```

Important options:

| Option | Meaning |
| --- | --- |
| `--output PATH` | Write the artifact to a file instead of stdout. Refuses overwrite unless `--force` is present. |
| `--format markdown\|json` | Select the portable artifact format. |
| `--destination NAME` | Record the intended receiving harness in provenance. |
| `--raw-summary` | Keep Claude's exact compact-summary wrapper. |
| `--claude-projects-root PATH` | Override transcript discovery root. |
| `--execution-cwd PATH` | Run the print-mode fork in this directory instead of an isolated temporary directory. The source-recorded CWD remains informational. (`--cwd` is accepted as a deprecated alias.) |
| `--instructions TEXT` | Add task-specific preservation focus to `/compact`. |
| `--model MODEL` | Override the model used for compaction. Normally omit this. |
| `--safe-mode` | Explicitly select the default: no user customizations, plugins, skills, or hooks in the compaction fork. |
| `--with-customizations` | Opt into user customizations, plugins, skills, and hooks for the compaction fork. |
| `--show-stream` | Mirror Claude's JSON event stream to stderr for debugging. |
| `--dry-run` | Resolve and print the intended command without invoking Claude. |
| `--max-file-paths N` | Deep-dive only: cap paths listed per category and epoch; `0` omits lists and a negative value lists all. |

Run `python3 .../session-handoff.py --help` or the subcommand help for the complete interface.
