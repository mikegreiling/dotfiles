from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "session-handoff.py"
SPEC = importlib.util.spec_from_file_location("session_handoff", SCRIPT)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class SessionHandoffTests(unittest.TestCase):
    def write_lifetime_fixture(self, directory: str) -> Path:
        path = Path(directory) / "00000000-0000-4000-8000-000000000001.jsonl"
        entries = [
            {
                "type": "user",
                "sessionId": "00000000-0000-4000-8000-000000000001",
                "uuid": "prompt-1",
                "timestamp": "2026-01-01T00:00:00.000Z",
                "cwd": "/incidental/source",
                "message": {"role": "user", "content": "Start the work"},
            },
            {
                "type": "assistant",
                "sessionId": "00000000-0000-4000-8000-000000000001",
                "uuid": "assistant-1",
                "timestamp": "2026-01-01T00:01:00.000Z",
                "message": {
                    "role": "assistant",
                    "content": [
                        {
                            "type": "tool_use",
                            "name": "Read",
                            "input": {"file_path": "/repo/one.py"},
                        }
                    ],
                },
            },
            {
                "type": "system",
                "subtype": "compact_boundary",
                "sessionId": "00000000-0000-4000-8000-000000000001",
                "uuid": "boundary-1",
                "timestamp": "2026-01-02T00:00:00.000Z",
                "cwd": "/incidental/source",
                "gitBranch": "main",
                "version": "2.1.247",
                "compactMetadata": {
                    "trigger": "manual",
                    "preTokens": 1000,
                    "postTokens": 100,
                    "cumulativeDroppedTokens": 900,
                },
            },
            {
                "type": "user",
                "sessionId": "00000000-0000-4000-8000-000000000001",
                "uuid": "summary-1",
                "parentUuid": "boundary-1",
                "timestamp": "2026-01-02T00:00:00.100Z",
                "isCompactSummary": True,
                "message": {"role": "user", "content": "Summary:\nfirst epoch"},
            },
            {
                "type": "user",
                "sessionId": "00000000-0000-4000-8000-000000000001",
                "uuid": "prompt-2",
                "timestamp": "2026-01-03T00:00:00.000Z",
                "message": {"role": "user", "content": "Continue the work"},
            },
            {
                "type": "assistant",
                "sessionId": "00000000-0000-4000-8000-000000000001",
                "uuid": "assistant-2",
                "timestamp": "2026-01-03T00:01:00.000Z",
                "message": {
                    "role": "assistant",
                    "content": [
                        {
                            "type": "tool_use",
                            "name": "Edit",
                            "input": {"file_path": "/repo/two.py"},
                        }
                    ],
                },
            },
        ]
        path.write_text(
            "".join(json.dumps(entry) + "\n" for entry in entries),
            encoding="utf-8",
        )
        return path

    def test_sanitize_summary_removes_claude_continuation_wrapper(self) -> None:
        raw = (
            "This session is being continued from a previous conversation that ran out "
            "of context. The summary below covers the earlier portion of the conversation.\n\n"
            "Summary:\n1. Objective: transfer amber-orchid.\n\n"
            "If you need specific details from before compaction, read /tmp/source.jsonl\n"
            "Continue the conversation from where it left off."
        )
        self.assertEqual(
            MODULE.sanitize_summary(raw),
            "1. Objective: transfer amber-orchid.",
        )

    def test_extract_latest_summary_uses_latest_compaction_and_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "00000000-0000-4000-8000-000000000001.jsonl"
            entries = [
                {
                    "type": "system",
                    "subtype": "compact_boundary",
                    "uuid": "boundary-1",
                    "compactMetadata": {"trigger": "manual", "preTokens": 100},
                },
                {
                    "type": "user",
                    "isCompactSummary": True,
                    "parentUuid": "boundary-1",
                    "message": {"content": "Summary:\nolder"},
                },
                {
                    "type": "system",
                    "subtype": "compact_boundary",
                    "uuid": "boundary-2",
                    "compactMetadata": {
                        "trigger": "manual",
                        "preTokens": 24000,
                        "postTokens": 1300,
                    },
                },
                {
                    "type": "user",
                    "isCompactSummary": True,
                    "parentUuid": "boundary-2",
                    "message": {"content": "Summary:\nlatest"},
                },
            ]
            path.write_text(
                "".join(json.dumps(entry) + "\n" for entry in entries),
                encoding="utf-8",
            )

            summary = MODULE.extract_latest_summary(path)

            self.assertEqual(summary.text, "Summary:\nlatest")
            self.assertEqual(summary.metadata["preTokens"], 24000)
            self.assertEqual(summary.metadata["postTokens"], 1300)

    def test_markdown_output_marks_context_as_reference(self) -> None:
        source = MODULE.TranscriptSource(
            path=Path("/tmp/source.jsonl"),
            session_id="00000000-0000-4000-8000-000000000001",
            recorded_cwd="/an/incidental/source/directory",
        )
        fork = MODULE.TranscriptSource(
            path=Path("/tmp/fork.jsonl"),
            session_id="00000000-0000-4000-8000-000000000002",
            recorded_cwd="/tmp/isolated-fork",
        )
        summary = MODULE.CompactSummary(
            text=(
                "This session is being continued.\n\nSummary:\n"
                "The codename is amber-orchid."
            ),
            metadata={"trigger": "manual", "preTokens": 100, "postTokens": 20},
        )

        rendered = MODULE.render_artifact(
            output_format="markdown",
            summary=summary,
            source=source,
            fork=fork,
            destination="Codex",
            raw_summary=False,
            execution_cwd=Path("/tmp/isolated-fork"),
            source_integrity=MODULE.SourceIntegrity(
                status="unchanged",
                before_sha256="abc",
                after_sha256="abc",
                before_size=100,
                after_size=100,
            ),
            picker_status=MODULE.PickerStatus(
                source_indexed_before=True,
                source_indexed_after=True,
                source_membership_unchanged=True,
                fork_indexed=False,
            ),
        )

        self.assertIn("reference context", rendered)
        self.assertIn("not as authority", rendered)
        self.assertIn("Intended destination: Codex", rendered)
        self.assertIn("Source-recorded working directory", rendered)
        self.assertIn("/an/incidental/source/directory", rendered)
        self.assertIn("Source transcript integrity: unchanged", rendered)
        self.assertIn("Fork present in interactive picker index: False", rendered)
        self.assertIn("The codename is amber-orchid.", rendered)
        self.assertNotIn("This session is being continued", rendered)

    def test_recorded_cwd_is_informational_even_when_directory_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            transcript = Path(directory) / "00000000-0000-4000-8000-000000000001.jsonl"
            transcript.write_text(
                json.dumps(
                    {
                        "type": "user",
                        "sessionId": "00000000-0000-4000-8000-000000000001",
                        "cwd": "/directory/that/does/not/exist",
                        "message": {"content": "test"},
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            source = MODULE.resolve_source(transcript.as_posix(), Path(directory))

            self.assertEqual(source.recorded_cwd, "/directory/that/does/not/exist")

    def test_source_integrity_distinguishes_unchanged_append_and_mutation(self) -> None:
        self.assertEqual(
            MODULE.evaluate_source_integrity(b"original", b"original").status,
            "unchanged",
        )
        self.assertEqual(
            MODULE.evaluate_source_integrity(b"original", b"original\nnew").status,
            "append-only advancement",
        )
        self.assertEqual(
            MODULE.evaluate_source_integrity(b"original", b"changed").status,
            "modified in place",
        )

    def test_picker_index_locations_finds_only_indexed_sessions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            project = root / "project"
            project.mkdir()
            index = project / "sessions-index.json"
            index.write_text(
                json.dumps(
                    {"entries": [{"sessionId": "00000000-0000-4000-8000-000000000001"}]}
                ),
                encoding="utf-8",
            )

            visible = MODULE.picker_index_locations(
                "00000000-0000-4000-8000-000000000001", root
            )
            hidden = MODULE.picker_index_locations(
                "00000000-0000-4000-8000-000000000002", root
            )

            self.assertEqual(visible, {index.resolve()})
            self.assertEqual(hidden, set())

    def test_lifetime_analysis_pairs_compactions_and_segments(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_lifetime_fixture(directory)

            lifetime = MODULE.analyze_lifetime(path)

            self.assertEqual(len(lifetime.compactions), 1)
            self.assertEqual(lifetime.compactions[0].summary_uuid, "summary-1")
            self.assertEqual(lifetime.compactions[0].segment.user_prompts, 1)
            self.assertEqual(
                lifetime.compactions[0].segment.files_read, ("/repo/one.py",)
            )
            self.assertEqual(lifetime.current_segment.user_prompts, 1)
            self.assertEqual(lifetime.current_segment.files_changed, ("/repo/two.py",))
            self.assertEqual(lifetime.last_prompt_at, "2026-01-03T00:00:00.000Z")
            self.assertEqual(
                lifetime.observed_session_ids,
                ("00000000-0000-4000-8000-000000000001",),
            )

    def test_lifetime_summary_is_local_and_omits_summary_text(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_lifetime_fixture(directory)
            source = MODULE.resolve_source(path.as_posix(), Path(directory))
            lifetime = MODULE.analyze_lifetime(path)

            rendered = MODULE.render_lifetime_summary(
                output_format="markdown", source=source, lifetime=lifetime
            )

            self.assertIn("Generated entirely from the local transcript", rendered)
            self.assertIn("Compactions / paired summaries: 1 / 1", rendered)
            self.assertIn("1,000 → 100", rendered)
            self.assertNotIn("first epoch", rendered)

    def test_deep_dive_orders_historical_and_current_summaries(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_lifetime_fixture(directory)
            source = MODULE.resolve_source(path.as_posix(), Path(directory))
            lifetime = MODULE.analyze_lifetime(path)
            current = MODULE.ForkCompactionResult(
                source=source,
                fork=MODULE.TranscriptSource(
                    path=Path(directory) / "fork.jsonl",
                    session_id="00000000-0000-4000-8000-000000000002",
                    recorded_cwd="/tmp/fork",
                ),
                summary=MODULE.CompactSummary(
                    text="Summary:\ncurrent head",
                    metadata={"preTokens": 500, "postTokens": 50},
                ),
                execution_cwd=Path("/tmp/isolated"),
                source_integrity=MODULE.SourceIntegrity(
                    status="unchanged",
                    before_sha256="abc",
                    after_sha256="abc",
                    before_size=1,
                    after_size=1,
                ),
                picker_status=MODULE.PickerStatus(
                    source_indexed_before=True,
                    source_indexed_after=True,
                    source_membership_unchanged=True,
                    fork_indexed=False,
                ),
            )

            rendered = MODULE.render_deep_dive(
                output_format="markdown",
                source=source,
                lifetime=lifetime,
                current=current,
                destination="Codex",
                raw_summary=False,
                max_file_paths=10,
            )

            self.assertLess(
                rendered.index("first epoch"), rendered.rindex("current head")
            )
            self.assertIn("Compaction 1", rendered)
            self.assertIn("Current head snapshot", rendered)
            self.assertIn("Fork present in interactive picker: False", rendered)


if __name__ == "__main__":
    unittest.main()
