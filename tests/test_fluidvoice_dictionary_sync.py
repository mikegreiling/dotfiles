from __future__ import annotations

import copy
import importlib.machinery
import importlib.util
import io
import json
import os
import socket
import sys
import tempfile
import threading
import time
import unittest
from contextlib import contextmanager, redirect_stderr, redirect_stdout
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from unittest import mock


REPO_SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "home/private_dot_local/private_bin/private_executable_fluidvoice-dictionary-sync"
)
LIVE_SCRIPT = Path.home() / ".local/bin/fluidvoice-dictionary-sync"
SCRIPT = REPO_SCRIPT if REPO_SCRIPT.exists() else LIVE_SCRIPT
loader = importlib.machinery.SourceFileLoader("fluidvoice_dictionary_sync", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
sync = importlib.util.module_from_spec(spec)
sys.modules[loader.name] = sync
loader.exec_module(sync)


ID_A = "11111111-1111-4111-8111-111111111111"
ID_B = "22222222-2222-4222-8222-222222222222"
ID_C = "33333333-3333-4333-8333-333333333333"


def replacement(item_id=ID_A, triggers=None, value="Acme"):
    return {"id": item_id, "triggers": triggers or ["ack me"], "replacement": value}


def word(text="Acme", weight=10, aliases=None):
    return {"text": text, "weight": weight, "aliases": aliases or []}


def document(replacements=None, words=None):
    return sync.normalize_document(
        {
            "version": 1,
            "replacements": replacements or [],
            "customWords": words or [],
        }
    )


class FakeAPI:
    def __init__(self, live, *, read_error=None, fail_custom_once=False):
        self.live = copy.deepcopy(live)
        self.read_error = read_error
        self.fail_custom_once = fail_custom_once
        self.calls = []

    def read_dictionary(self):
        self.calls.append(("read", None))
        if self.read_error:
            raise self.read_error
        return copy.deepcopy(self.live)

    def write_replacements(self, entries):
        self.calls.append(("replacements", copy.deepcopy(entries)))
        self.live["replacements"] = copy.deepcopy(entries)

    def write_custom_words(self, entries):
        self.calls.append(("customWords", copy.deepcopy(entries)))
        if self.fail_custom_once:
            self.fail_custom_once = False
            raise sync.APIError("simulated custom-word POST failure")
        self.live["customWords"] = copy.deepcopy(entries)


class _HTTPHandler(BaseHTTPRequestHandler):
    routes = {}

    def do_GET(self):
        status, body, delay = self.routes.get(self.path, (404, {"error": "not found"}, 0))
        if delay:
            time.sleep(delay)
        payload = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        try:
            self.wfile.write(payload)
        except BrokenPipeError:
            pass

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", "0"))
        if content_length:
            self.rfile.read(content_length)
        self.do_GET()

    def log_message(self, _format, *_args):
        pass


@contextmanager
def api_server(routes):
    handler = type("ConfiguredHandler", (_HTTPHandler,), {"routes": routes})
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{server.server_port}"
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


class MergeTests(unittest.TestCase):
    def test_normalization_is_stable_and_semantic(self):
        raw = {
            "version": 1,
            "replacements": [
                {"id": ID_A.upper(), "triggers": [" ACK ME ", "ack me", "A.C.M.E."], "replacement": " Acme "}
            ],
            "customWords": [{"text": " Acme ", "weight": 10.0, "aliases": [" ack me ", "ack me"]}],
        }
        first = sync.normalize_document(raw)
        second = sync.normalize_document(first)
        self.assertEqual(first, second)
        self.assertEqual(first["replacements"][0]["triggers"], ["a.c.m.e.", "ack me"])
        self.assertEqual(first["customWords"][0]["weight"], 10)

    def test_missing_top_level_fields_are_not_interpreted_as_empty(self):
        with self.assertRaisesRegex(sync.SyncError, "omitted required field"):
            sync.normalize_document({})

    def test_deletion_on_managed_side_propagates_when_live_is_unchanged(self):
        base = document([replacement()])
        merged, conflicts = sync.merge_documents(base, document(), base)
        self.assertEqual(conflicts, [])
        self.assertEqual(merged, document())

    def test_deletion_on_live_side_propagates_when_managed_is_unchanged(self):
        base = document([replacement()])
        merged, conflicts = sync.merge_documents(base, base, document())
        self.assertEqual(conflicts, [])
        self.assertEqual(merged, document())

    def test_custom_word_deletion_propagates_without_resurrection(self):
        base = document(words=[word()])
        merged, conflicts = sync.merge_documents(base, base, document())
        self.assertEqual(conflicts, [])
        self.assertEqual(merged, document())

    def test_addition_from_one_side_propagates(self):
        base = document()
        added = document([replacement()])
        merged, conflicts = sync.merge_documents(base, added, base)
        self.assertEqual(conflicts, [])
        self.assertEqual(merged, added)

    def test_both_delete_stays_deleted(self):
        base = document([replacement()], [word()])
        merged, conflicts = sync.merge_documents(base, document(), document())
        self.assertEqual(conflicts, [])
        self.assertEqual(merged, document())

    def test_delete_versus_modify_is_a_conflict(self):
        base = document([replacement()])
        modified = document([replacement(triggers=["acne"], value="Acme Inc.")])
        merged, conflicts = sync.merge_documents(base, document(), modified)
        self.assertIsNone(merged)
        self.assertIn("changed differently", "\n".join(conflicts))

    def test_custom_word_delete_versus_modify_is_a_conflict(self):
        base = document(words=[word()])
        modified = document(words=[word(weight=15)])
        merged, conflicts = sync.merge_documents(base, document(), modified)
        self.assertIsNone(merged)
        self.assertIn("custom word", "\n".join(conflicts))

    def test_nonconflicting_divergent_changes_merge(self):
        base = document([replacement()], [word()])
        managed = document([replacement(triggers=["acne"])], [word()])
        live = document([replacement()], [word(weight=12)])
        merged, conflicts = sync.merge_documents(base, managed, live)
        self.assertEqual(conflicts, [])
        self.assertEqual(merged["replacements"][0]["triggers"], ["acne"])
        self.assertEqual(merged["customWords"][0]["weight"], 12)

    def test_differently_modified_same_item_conflicts_deterministically(self):
        base = document([replacement()])
        managed = document([replacement(value="Acme Corp")])
        live = document([replacement(value="Acme Company")])
        one = sync.merge_documents(base, managed, live)[1]
        two = sync.merge_documents(base, managed, live)[1]
        self.assertEqual(one, two)
        self.assertIn("Acme Company", one[0])
        self.assertIn("Acme Corp", one[0])

    def test_independent_equivalent_additions_are_deduplicated(self):
        managed = document([replacement(ID_B)])
        live = document([replacement(ID_A)])
        merged, conflicts = sync.merge_documents(document(), managed, live)
        self.assertEqual(conflicts, [])
        self.assertEqual(len(merged["replacements"]), 1)
        self.assertEqual(merged["replacements"][0]["id"], ID_A)

    def test_trigger_collision_is_reported_instead_of_overwritten(self):
        managed = document([replacement(ID_A, ["same"], "First")])
        live = document([replacement(ID_B, ["same"], "Second")])
        merged, conflicts = sync.merge_documents(document(), managed, live)
        self.assertIsNone(merged)
        self.assertIn("trigger 'same' maps to both", "\n".join(conflicts))


class RunTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        root = Path(self.temporary.name)
        self.managed = root / "config/dictionary.json"
        self.base = root / "state/base.json"
        self.environment = mock.patch.dict(
            os.environ,
            {
                "FLUIDVOICE_DICTIONARY_FILE": str(self.managed),
                "FLUIDVOICE_DICTIONARY_STATE_FILE": str(self.base),
            },
            clear=False,
        )
        self.environment.start()

    def tearDown(self):
        self.environment.stop()
        self.temporary.cleanup()

    def write(self, path, value):
        sync.write_document(path, value)

    def quiet_run(self, mode, api, bootstrap_from=None):
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            return sync.run(mode, api, bootstrap_from)

    def test_first_run_with_empty_managed_safely_exports_live(self):
        self.write(self.managed, document())
        live = document([replacement()], [word()])
        api = FakeAPI(live)
        self.assertEqual(self.quiet_run("sync", api), 0)
        self.assertEqual(sync.read_document(self.managed, missing_ok=False, description="test"), live)
        self.assertEqual(sync.read_document(self.base, missing_ok=False, description="test"), live)

    def test_first_run_two_different_nonempty_states_refuses_to_guess(self):
        managed = document([replacement(ID_A, value="Managed")])
        live = document([replacement(ID_B, value="Live")])
        self.write(self.managed, managed)
        before = self.managed.read_bytes()
        api = FakeAPI(live)
        self.assertEqual(self.quiet_run("sync", api), 2)
        self.assertEqual(self.managed.read_bytes(), before)
        self.assertFalse(self.base.exists())
        self.assertEqual(api.calls, [("read", None)])

    def test_explicit_first_run_bootstrap_from_managed(self):
        managed = document([replacement(ID_A, value="Managed")])
        live = document([replacement(ID_B, value="Live")])
        self.write(self.managed, managed)
        api = FakeAPI(live)
        self.assertEqual(self.quiet_run("sync", api, "managed"), 0)
        self.assertEqual(api.live, managed)
        self.assertEqual(sync.read_document(self.base, missing_ok=False, description="test"), managed)

    def test_idempotent_second_sync_performs_no_writes(self):
        value = document([replacement()], [word()])
        self.write(self.managed, value)
        self.write(self.base, value)
        api = FakeAPI(value)
        self.assertEqual(self.quiet_run("sync", api), 0)
        first_bytes = self.managed.read_bytes()
        api.calls.clear()
        self.assertEqual(self.quiet_run("sync", api), 0)
        self.assertEqual(api.calls, [("read", None)])
        self.assertEqual(self.managed.read_bytes(), first_bytes)

    def test_api_read_failure_changes_nothing(self):
        value = document([replacement()])
        self.write(self.managed, value)
        self.write(self.base, value)
        managed_before = self.managed.read_bytes()
        base_before = self.base.read_bytes()
        api = FakeAPI(value, read_error=sync.APIError("app is not running"))
        with self.assertRaisesRegex(sync.APIError, "not running"):
            sync.run("sync", api)
        self.assertEqual(self.managed.read_bytes(), managed_before)
        self.assertEqual(self.base.read_bytes(), base_before)

    def test_partial_write_failure_restores_original_live_state(self):
        original = document([replacement()], [word()])
        merged = document([replacement(triggers=["updated"])], [word(weight=15)])
        self.write(self.managed, merged)
        self.write(self.base, original)
        managed_before = self.managed.read_bytes()
        base_before = self.base.read_bytes()
        api = FakeAPI(original, fail_custom_once=True)
        with self.assertRaisesRegex(sync.APIError, "original live dictionary was restored"):
            sync.run("sync", api)
        self.assertEqual(api.live, original)
        self.assertEqual(self.managed.read_bytes(), managed_before)
        self.assertEqual(self.base.read_bytes(), base_before)
        self.assertEqual([call[0] for call in api.calls], ["read", "replacements", "customWords", "replacements", "customWords"])

    def test_status_is_read_only_and_reports_divergence(self):
        managed = document([replacement()])
        live = document([replacement()], [word()])
        self.write(self.managed, managed)
        self.write(self.base, managed)
        before = self.managed.read_bytes()
        api = FakeAPI(live)
        self.assertEqual(self.quiet_run("status", api), 1)
        self.assertEqual(self.managed.read_bytes(), before)
        self.assertEqual(api.calls, [("read", None)])


class APIFailureTests(unittest.TestCase):
    def valid_routes(self):
        return {
            "/v1/health": (200, {"status": "ok", "version": "1.2.3"}, 0),
            "/v1/dictionary/replacements": (200, {"count": 0, "items": []}, 0),
            "/v1/dictionary/custom-words": (200, {"count": 0, "items": []}, 0),
        }

    def test_app_not_running_is_conspicuous(self):
        probe = socket.socket()
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
        probe.close()
        api = sync.FluidVoiceAPI(f"http://127.0.0.1:{port}", timeout=0.1)
        with self.assertRaisesRegex(sync.APIError, "Start FluidVoice"):
            api.read_dictionary()

    def test_non_loopback_api_url_is_rejected(self):
        with self.assertRaisesRegex(sync.SyncError, "loopback"):
            sync.FluidVoiceAPI("https://example.invalid")

    def test_timeout_is_conspicuous(self):
        routes = self.valid_routes()
        routes["/v1/health"] = (200, {"status": "ok", "version": "1.2.3"}, 0.2)
        with api_server(routes) as url:
            with self.assertRaisesRegex(sync.APIError, "cannot reach"):
                sync.FluidVoiceAPI(url, timeout=0.02).read_dictionary()

    def test_non_success_response_is_conspicuous(self):
        routes = self.valid_routes()
        routes["/v1/health"] = (503, {"error": "not ready"}, 0)
        with api_server(routes) as url:
            with self.assertRaisesRegex(sync.APIError, "HTTP 503"):
                sync.FluidVoiceAPI(url).read_dictionary()

    def test_malformed_json_is_rejected(self):
        routes = self.valid_routes()
        routes["/v1/dictionary/replacements"] = (200, b"not-json", 0)
        with api_server(routes) as url:
            with self.assertRaisesRegex(sync.APIError, "invalid JSON"):
                sync.FluidVoiceAPI(url).read_dictionary()

    def test_contract_drift_is_rejected(self):
        routes = self.valid_routes()
        routes["/v1/dictionary/replacements"] = (
            200,
            {"count": 1, "items": [{"triggers": ["ack me"], "replacement": "Acme"}]},
            0,
        )
        with api_server(routes) as url:
            with self.assertRaisesRegex(sync.APIError, "omitted required field.*id"):
                sync.FluidVoiceAPI(url).read_dictionary()

    def test_count_mismatch_is_rejected(self):
        routes = self.valid_routes()
        routes["/v1/dictionary/custom-words"] = (200, {"count": 1, "items": []}, 0)
        with api_server(routes) as url:
            with self.assertRaisesRegex(sync.APIError, "does not match"):
                sync.FluidVoiceAPI(url).read_dictionary()

    def test_empty_but_valid_dictionary_is_accepted(self):
        with api_server(self.valid_routes()) as url:
            self.assertEqual(sync.FluidVoiceAPI(url).read_dictionary(), document())

    def test_malformed_write_response_is_rejected(self):
        routes = self.valid_routes()
        routes["/v1/dictionary/replacements"] = (200, {"items": [replacement()]}, 0)
        with api_server(routes) as url:
            with self.assertRaisesRegex(sync.APIError, "omitted required count/items"):
                sync.FluidVoiceAPI(url).write_replacements([replacement()])


if __name__ == "__main__":
    unittest.main()
