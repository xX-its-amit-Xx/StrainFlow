#!/usr/bin/env python3
"""
merge_tables.py — merge per-sample abundance and strain TSVs into
analysis-ready combined tables (TSV + Parquet).

Part of StrainFlow | GPL v3.0
"""

from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from pathlib import Path
from typing import Optional

import pandas as pd

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
log = logging.getLogger(__name__)


# ── parsers ───────────────────────────────────────────────────────────────────

def parse_bracken(path: Path) -> pd.DataFrame:
    """Parse a Bracken output file into a tidy DataFrame."""
    df = pd.read_csv(path, sep="\t")
    required_cols = {"name", "fraction_total_reads"}
    if not required_cols.issubset(df.columns):
        raise ValueError(f"Bracken file {path} missing columns: {required_cols - set(df.columns)}")
    sample_id = _sample_id_from_path(path, ".bracken.")
    df = df.rename(columns={"name": "taxon", "fraction_total_reads": "rel_abundance"})
    df["sample"] = sample_id
    df["tool"] = "bracken"
    return df[["sample", "tool", "taxon", "rel_abundance"]]


def parse_metaphlan4(path: Path) -> pd.DataFrame:
    """Parse a MetaPhlAn4 profile into a tidy DataFrame (species level only)."""
    rows = []
    sample_id = _sample_id_from_path(path, ".metaphlan4.")
    with open(path) as fh:
        for line in fh:
            if line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 2:
                continue
            clade, rel_ab = parts[0], float(parts[1])
            # Species-level lines end with |s__<name> and contain no further |
            if re.search(r"\|s__[^|]+$", clade):
                taxon = clade.split("|")[-1].replace("s__", "")
                rows.append({"sample": sample_id, "tool": "metaphlan4",
                             "taxon": taxon, "rel_abundance": rel_ab})
    return pd.DataFrame(rows, columns=["sample", "tool", "taxon", "rel_abundance"])


def parse_strain_tsv(path: Path) -> pd.DataFrame:
    """Parse a StrainPhlAn or inStrain compare TSV into a tidy DataFrame."""
    sample_id = _sample_id_from_path(path, suffix=None)
    df = pd.read_csv(path, sep="\t")
    df["source_file"] = path.name
    df["sample"] = sample_id
    return df


def _sample_id_from_path(path: Path, suffix: Optional[str]) -> str:
    """Extract sample ID by stripping known suffixes from the filename stem."""
    name = path.stem
    if suffix and suffix in name:
        name = name[: name.index(suffix)]
    return name


# ── merging ───────────────────────────────────────────────────────────────────

def merge_abundance(files: list[Path]) -> pd.DataFrame:
    """Merge all per-sample abundance tables into a single wide matrix."""
    frames: list[pd.DataFrame] = []
    for f in files:
        try:
            if ".bracken." in f.name:
                frames.append(parse_bracken(f))
            elif ".metaphlan4." in f.name:
                frames.append(parse_metaphlan4(f))
            else:
                log.warning("Skipping unrecognised abundance file: %s", f.name)
        except Exception as exc:  # noqa: BLE001
            log.error("Failed to parse %s: %s", f, exc)

    if not frames:
        raise RuntimeError("No valid abundance files parsed — check inputs.")

    long_df = pd.concat(frames, ignore_index=True)
    # Pivot to wide: rows = taxa, columns = sample_tool
    wide_df = long_df.pivot_table(
        index="taxon",
        columns=["sample", "tool"],
        values="rel_abundance",
        fill_value=0.0,
    )
    wide_df.columns = ["_".join(col) for col in wide_df.columns]
    return wide_df.reset_index()


def merge_strains(files: list[Path]) -> pd.DataFrame:
    """Merge all per-sample strain TSVs into a single table."""
    frames = []
    for f in files:
        try:
            frames.append(parse_strain_tsv(f))
        except Exception as exc:  # noqa: BLE001
            log.error("Failed to parse strain file %s: %s", f, exc)
    if not frames:
        log.warning("No valid strain files found; returning empty DataFrame.")
        return pd.DataFrame()
    return pd.concat(frames, ignore_index=True)


# ── I/O ───────────────────────────────────────────────────────────────────────

def write_outputs(df: pd.DataFrame, prefix: str, label: str) -> None:
    """Write DataFrame to TSV and Parquet with the given prefix and label."""
    tsv_path     = Path(f"{prefix}_{label}.tsv")
    parquet_path = Path(f"{prefix}_{label}.parquet")

    df.to_csv(tsv_path, sep="\t", index=False)
    log.info("Wrote %d rows × %d cols → %s", len(df), len(df.columns), tsv_path)

    df.to_parquet(parquet_path, index=False, engine="pyarrow")
    log.info("Wrote Parquet → %s", parquet_path)


# ── CLI ───────────────────────────────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Merge per-sample StrainFlow tables into analysis-ready artifacts."
    )
    p.add_argument(
        "--abundance-files", nargs="+", required=True,
        type=Path, metavar="FILE",
        help="Bracken and/or MetaPhlAn4 TSV files to merge.",
    )
    p.add_argument(
        "--strain-files", nargs="+", required=False, default=[],
        type=Path, metavar="FILE",
        help="StrainPhlAn / inStrain compare TSV files to merge.",
    )
    p.add_argument(
        "--out-prefix", default="strainflow", metavar="PREFIX",
        help="Output filename prefix (default: strainflow).",
    )
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    log.info("Merging %d abundance file(s)...", len(args.abundance_files))
    abundance_df = merge_abundance(args.abundance_files)
    write_outputs(abundance_df, args.out_prefix, "abundance")

    log.info("Merging %d strain file(s)...", len(args.strain_files))
    strain_df = merge_strains(args.strain_files)
    if not strain_df.empty:
        write_outputs(strain_df, args.out_prefix, "strains")

    return 0


if __name__ == "__main__":
    sys.exit(main())
