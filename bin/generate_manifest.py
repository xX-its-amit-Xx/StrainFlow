#!/usr/bin/env python3
"""
generate_manifest.py — emit a JSON provenance manifest for each StrainFlow run.

Fields:
  - pipeline_version
  - git_commit
  - timestamp (ISO-8601)
  - samples  (list of sample IDs)
  - params   (all pipeline parameters)
  - tool_versions (resolved at runtime from which/--version)

Part of StrainFlow | GPL v3.0
"""

from __future__ import annotations

import argparse
import json
import logging
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
log = logging.getLogger(__name__)

# Tools to version-probe; (binary, version_flag)
TOOL_VERSION_CMDS: list[tuple[str, str]] = [
    ("fastp",       "--version"),
    ("fastqc",      "--version"),
    ("bowtie2",     "--version"),
    ("kraken2",     "--version"),
    ("bracken",     "--version"),
    ("metaphlan",   "--version"),
    ("strainphlan", "--version"),
    ("inStrain",    "--version"),
    ("megahit",     "--version"),
    ("spades.py",   "--version"),
    ("metabat2",    "--help"),
    ("checkm",      "--version"),
    ("humann",      "--version"),
    ("multiqc",     "--version"),
]


def probe_tool_version(binary: str, flag: str) -> str:
    """Run `binary flag` and return the first non-empty output line."""
    if not shutil.which(binary):
        return "not_found"
    try:
        result = subprocess.run(
            [binary, flag],
            capture_output=True,
            text=True,
            timeout=10,
        )
        output = (result.stdout + result.stderr).strip()
        return output.splitlines()[0] if output else "unknown"
    except Exception as exc:  # noqa: BLE001
        return f"error:{exc}"


def collect_tool_versions() -> dict[str, str]:
    return {binary: probe_tool_version(binary, flag) for binary, flag in TOOL_VERSION_CMDS}


def build_manifest(
    sample_ids: list[str],
    pipeline_version: str,
    git_commit: str,
    run_params: dict[str, Any],
) -> dict[str, Any]:
    return {
        "schema_version": "1.0",
        "pipeline": "StrainFlow",
        "pipeline_version": pipeline_version,
        "git_commit": git_commit,
        "timestamp": datetime.now(tz=timezone.utc).isoformat(),
        "samples": sample_ids,
        "params": run_params,
        "tool_versions": collect_tool_versions(),
    }


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Emit a StrainFlow run manifest JSON.")
    p.add_argument("--sample-ids",  required=True, help="Comma-separated sample IDs.")
    p.add_argument("--version",     required=True, dest="pipeline_version")
    p.add_argument("--git-commit",  required=True)
    p.add_argument("--params",      required=True, help="JSON-encoded params dict.")
    p.add_argument("--output",      required=True, type=Path)
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    sample_ids  = [s.strip() for s in args.sample_ids.split(",") if s.strip()]
    run_params  = json.loads(args.params)

    manifest = build_manifest(
        sample_ids=sample_ids,
        pipeline_version=args.pipeline_version,
        git_commit=args.git_commit,
        run_params=run_params,
    )

    args.output.write_text(json.dumps(manifest, indent=2, default=str))
    log.info("Run manifest written → %s", args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
