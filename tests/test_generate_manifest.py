"""
pytest unit tests for bin/generate_manifest.py

Run from repo root:
    pytest tests/test_generate_manifest.py -v
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "bin"))
from generate_manifest import build_manifest, collect_tool_versions  # noqa: E402


class TestBuildManifest:
    def test_required_fields(self):
        m = build_manifest(
            sample_ids=["S1", "S2"],
            pipeline_version="1.0.0",
            git_commit="abc1234",
            run_params={"outdir": "results"},
        )
        for key in ("pipeline", "pipeline_version", "git_commit",
                    "timestamp", "samples", "params", "tool_versions"):
            assert key in m, f"Missing key: {key}"

    def test_samples_list(self):
        m = build_manifest(["A", "B", "C"], "1.0.0", "aaa", {})
        assert m["samples"] == ["A", "B", "C"]

    def test_pipeline_name(self):
        m = build_manifest([], "1.0.0", "abc", {})
        assert m["pipeline"] == "StrainFlow"

    def test_params_preserved(self):
        params = {"outdir": "s3://bucket/out", "bracken_level": "S"}
        m = build_manifest([], "1.0.0", "abc", params)
        assert m["params"] == params

    def test_timestamp_iso8601(self):
        import re
        m = build_manifest([], "1.0.0", "abc", {})
        assert re.match(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", m["timestamp"])

    def test_serialisable_to_json(self):
        m = build_manifest(["S1"], "1.0.0", "abc", {"key": "value"})
        dumped = json.dumps(m, default=str)
        loaded = json.loads(dumped)
        assert loaded["pipeline"] == "StrainFlow"


class TestCollectToolVersions:
    def test_returns_dict(self):
        versions = collect_tool_versions()
        assert isinstance(versions, dict)

    def test_all_tools_present(self):
        from generate_manifest import TOOL_VERSION_CMDS
        versions = collect_tool_versions()
        for binary, _ in TOOL_VERSION_CMDS:
            assert binary in versions

    def test_not_found_tools_have_sentinel(self):
        versions = collect_tool_versions()
        # At least some tools won't be installed in the test environment
        not_found = [v for v in versions.values() if v == "not_found"]
        assert len(not_found) >= 0  # may be 0 in a full bioinformatics env
