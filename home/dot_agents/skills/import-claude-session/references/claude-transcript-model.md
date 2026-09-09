# Claude Code transcript and compaction model

Use this reference when explaining lifetime reports, investigating an unfamiliar transcript version, or changing the parser.

## Compaction is an in-session boundary

Claude Code persists a compaction in the same JSONL transcript and under the same session ID. A normal compaction does not create a predecessor transcript or mint a successor session ID.

The observed pair is:

1. a `system` record with `subtype: "compact_boundary"`;
2. a `user` record with `isCompactSummary: true` whose `parentUuid` is the boundary's `uuid`.

The boundary contains `compactMetadata`, commonly including:

- `trigger`;
- `preTokens` and `postTokens`;
- `cumulativeDroppedTokens`;
- `durationMs`;
- preserved-message and preserved-segment UUID metadata.

The paired user record contains the seeded summary text. Historical records remain earlier in the same JSONL, so a lifetime view is reconstructed by scanning boundaries in file order and pairing them by UUID.

Claude's documentation independently exposes compaction as a `compact_boundary` event and describes a `SessionStart` hook reason of `compact`. See:

- <https://code.claude.com/docs/en/agent-sdk/skills>
- <https://code.claude.com/docs/en/hooks>

## Forking is different

`--fork-session` creates a new session ID. A fork transcript can contain copied records that retain the source session ID, followed by new records carrying the fork ID. Therefore, multiple session IDs observed in one transcript indicate copied fork history, not compaction ancestry.

Do not assume an explicit `sourceSessionId` pointer exists. Infer only what the transcript proves, and label a sequence of copied session IDs as observed provenance rather than a guaranteed ancestry graph.

## Resume and picker behavior

Exact-ID resume can locate sessions across working directories. Print-mode (`claude -p`) sessions do not appear in the interactive picker but remain resumable by exact ID. Forking leaves the original session unchanged. See <https://code.claude.com/docs/en/sessions>.

The script still verifies these properties at runtime because local behavior and transcript schemas can change:

- source bytes are unchanged or append-only if the source is concurrently active;
- source picker-index membership is identical before and after;
- the fork has a distinct session ID;
- the print-mode fork occurs in no `sessions-index.json`.

## Statistics and limits

The lifetime analyzer reports exact counts for JSONL records and explicit built-in tool calls. “Files read” currently means unique `file_path` values passed to `Read`; “files changed” means paths passed to `Edit`, `Write`, `MultiEdit`, or `NotebookEdit`.

Shell commands, MCP tools, plugins, hooks, subagent transcripts, and external processes can access additional files. Do not describe the explicit-path counts as a complete filesystem audit.

Summary character and word counts are exact for persisted text. Token values are reported only when Claude recorded them in compaction metadata; do not substitute character-based token estimates without clearly labeling them estimates.
