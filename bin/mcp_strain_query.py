#!/usr/bin/env python3
"""
mcp_strain_query.py — optional MCP tool exposing StrainFlow analysis-ready tables.

Usage as MCP server (stdio transport):
    python3 bin/mcp_strain_query.py --abundance path/to/strainflow_abundance.parquet \
                                    --strains   path/to/strainflow_strains.parquet

Exposes two MCP tools:
  - get_strain_abundances(sample_id: str) → table of taxa + rel_abundance
  - list_samples()                         → list of all sample IDs in the run

Part of StrainFlow | GPL v3.0
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Any

log = logging.getLogger(__name__)


def _load_parquet(path: Path) -> "pd.DataFrame":
    try:
        import pandas as pd
        return pd.read_parquet(path)
    except ImportError:
        log.error("pandas / pyarrow required: pip install pandas pyarrow")
        raise


class StrainFlowMCP:
    """Minimal MCP server (JSON-RPC over stdio) exposing StrainFlow data."""

    TOOLS = [
        {
            "name": "get_strain_abundances",
            "description": (
                "Return taxonomic abundance data for a given sample from a "
                "StrainFlow run. Columns: taxon, rel_abundance_bracken, "
                "rel_abundance_metaphlan4."
            ),
            "inputSchema": {
                "type": "object",
                "properties": {
                    "sample_id": {
                        "type": "string",
                        "description": "The sample identifier (e.g. 'SRR12345_1').",
                    }
                },
                "required": ["sample_id"],
            },
        },
        {
            "name": "list_samples",
            "description": "List all sample IDs present in the StrainFlow run outputs.",
            "inputSchema": {"type": "object", "properties": {}},
        },
    ]

    def __init__(self, abundance_path: Path, strains_path: Path | None = None) -> None:
        self._abundance = _load_parquet(abundance_path)
        self._strains   = _load_parquet(strains_path) if strains_path else None

        # Detect sample columns (pattern: <sample>_<tool>)
        import re
        tool_pat = re.compile(r"_(?:bracken|metaphlan4)$")
        self._samples = sorted({
            tool_pat.sub("", c)
            for c in self._abundance.columns
            if tool_pat.search(c)
        })

    # ── tool dispatch ─────────────────────────────────────────────────────────

    def call_tool(self, name: str, arguments: dict[str, Any]) -> Any:
        if name == "get_strain_abundances":
            return self._get_strain_abundances(**arguments)
        if name == "list_samples":
            return self._list_samples()
        raise ValueError(f"Unknown tool: {name!r}")

    def _list_samples(self) -> dict[str, Any]:
        return {"samples": self._samples, "count": len(self._samples)}

    def _get_strain_abundances(self, sample_id: str) -> dict[str, Any]:
        import pandas as pd

        bracken_col    = f"{sample_id}_bracken"
        metaphlan_col  = f"{sample_id}_metaphlan4"
        available_cols = [c for c in [bracken_col, metaphlan_col]
                          if c in self._abundance.columns]

        if not available_cols:
            raise ValueError(
                f"Sample '{sample_id}' not found. "
                f"Available samples: {self._samples}"
            )

        sub = self._abundance[["taxon"] + available_cols].copy()
        sub = sub[(sub[available_cols] > 0).any(axis=1)]
        sub = sub.sort_values(available_cols[0], ascending=False)
        return {
            "sample_id": sample_id,
            "rows": sub.to_dict(orient="records"),
            "n_taxa": len(sub),
        }

    # ── JSON-RPC stdio loop ───────────────────────────────────────────────────

    def _respond(self, request_id: Any, result: Any | None = None,
                 error: dict | None = None) -> None:
        resp: dict[str, Any] = {"jsonrpc": "2.0", "id": request_id}
        if error:
            resp["error"] = error
        else:
            resp["result"] = result
        sys.stdout.write(json.dumps(resp) + "\n")
        sys.stdout.flush()

    def run(self) -> None:
        for raw in sys.stdin:
            raw = raw.strip()
            if not raw:
                continue
            try:
                req = json.loads(raw)
            except json.JSONDecodeError as exc:
                self._respond(None, error={"code": -32700, "message": str(exc)})
                continue

            req_id  = req.get("id")
            method  = req.get("method", "")
            params  = req.get("params", {})

            if method == "initialize":
                self._respond(req_id, result={
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "strainflow-mcp", "version": "1.0.0"},
                })
            elif method == "tools/list":
                self._respond(req_id, result={"tools": self.TOOLS})
            elif method == "tools/call":
                tool_name = params.get("name", "")
                arguments = params.get("arguments", {})
                try:
                    result = self.call_tool(tool_name, arguments)
                    self._respond(req_id, result={
                        "content": [{"type": "text", "text": json.dumps(result, default=str)}]
                    })
                except Exception as exc:  # noqa: BLE001
                    self._respond(req_id, error={"code": -32603, "message": str(exc)})
            elif method == "notifications/initialized":
                pass  # no-op notification
            else:
                self._respond(req_id, error={"code": -32601, "message": f"Unknown method: {method}"})


def main() -> int:
    parser = argparse.ArgumentParser(description="StrainFlow MCP strain-query server.")
    parser.add_argument("--abundance", type=Path, required=True,
                        help="Path to strainflow_abundance.parquet")
    parser.add_argument("--strains", type=Path, required=False, default=None,
                        help="Path to strainflow_strains.parquet (optional)")
    args = parser.parse_args()

    server = StrainFlowMCP(args.abundance, args.strains)
    log.info("StrainFlow MCP server ready (stdio transport)")
    server.run()
    return 0


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    sys.exit(main())
