"""
pytest unit tests for bin/merge_tables.py

Run from repo root:
    pytest tests/test_merge_tables.py -v
"""

from __future__ import annotations

import sys
import textwrap
from pathlib import Path

import pandas as pd
import pytest

# Allow importing from bin/ without installing the package
sys.path.insert(0, str(Path(__file__).parent.parent / "bin"))
from merge_tables import (  # noqa: E402
    merge_abundance,
    merge_strains,
    parse_bracken,
    parse_metaphlan4,
)


# ── fixtures ──────────────────────────────────────────────────────────────────

BRACKEN_CONTENT = textwrap.dedent("""\
    name\ttaxonomy_id\ttaxonomy_lvl\tkraken_assigned_reads\tadded_reads\tnew_est_reads\tfraction_total_reads
    Staphylococcus aureus\t1280\tS\t5000\t200\t5200\t0.52
    Cutibacterium acnes\t1743\tS\t3000\t100\t3100\t0.31
    Malassezia globosa\t76773\tS\t1700\t0\t1700\t0.17
""")

METAPHLAN4_CONTENT = textwrap.dedent("""\
    #mpa_v4|mpa_vJan21_CHOCOPhlAnSGB_202103|0
    #clade_name\tNCBI_tax_id\trelative_abundance\tadditional_species
    k__Bacteria\t2\t83.0
    k__Bacteria|p__Firmicutes\t1239\t52.0
    k__Bacteria|p__Firmicutes|c__Bacilli|o__Lactobacillales|f__Staphylococcaceae|g__Staphylococcus|s__Staphylococcus_aureus\t1280\t52.0
    k__Bacteria|p__Actinobacteria|c__Actinobacteria|o__Propionibacteriales|f__Propionibacteriaceae|g__Cutibacterium|s__Cutibacterium_acnes\t1743\t31.0
""")


@pytest.fixture
def bracken_file(tmp_path: Path) -> Path:
    f = tmp_path / "SRR001_R1.bracken.S.txt"
    f.write_text(BRACKEN_CONTENT)
    return f


@pytest.fixture
def metaphlan_file(tmp_path: Path) -> Path:
    f = tmp_path / "SRR001_R1.metaphlan4.txt"
    f.write_text(METAPHLAN4_CONTENT)
    return f


@pytest.fixture
def bracken_file2(tmp_path: Path) -> Path:
    content = BRACKEN_CONTENT.replace("0.52", "0.60").replace("0.31", "0.25").replace("0.17", "0.15")
    f = tmp_path / "SRR002_R1.bracken.S.txt"
    f.write_text(content)
    return f


# ── parse_bracken ─────────────────────────────────────────────────────────────

class TestParseBracken:
    def test_returns_dataframe(self, bracken_file: Path):
        df = parse_bracken(bracken_file)
        assert isinstance(df, pd.DataFrame)

    def test_columns(self, bracken_file: Path):
        df = parse_bracken(bracken_file)
        assert set(df.columns) == {"sample", "tool", "taxon", "rel_abundance"}

    def test_sample_id_extracted(self, bracken_file: Path):
        df = parse_bracken(bracken_file)
        assert (df["sample"] == "SRR001_R1").all()

    def test_tool_label(self, bracken_file: Path):
        df = parse_bracken(bracken_file)
        assert (df["tool"] == "bracken").all()

    def test_row_count(self, bracken_file: Path):
        df = parse_bracken(bracken_file)
        assert len(df) == 3

    def test_abundances_sum_to_one(self, bracken_file: Path):
        df = parse_bracken(bracken_file)
        assert abs(df["rel_abundance"].sum() - 1.0) < 1e-6

    def test_missing_columns_raises(self, tmp_path: Path):
        bad = tmp_path / "bad.bracken.S.txt"
        bad.write_text("col1\tcol2\na\tb\n")
        with pytest.raises(ValueError, match="missing columns"):
            parse_bracken(bad)


# ── parse_metaphlan4 ──────────────────────────────────────────────────────────

class TestParseMetaPhlAn4:
    def test_returns_dataframe(self, metaphlan_file: Path):
        df = parse_metaphlan4(metaphlan_file)
        assert isinstance(df, pd.DataFrame)

    def test_only_species_level(self, metaphlan_file: Path):
        df = parse_metaphlan4(metaphlan_file)
        # Should only have species-level entries (s__...)
        assert len(df) == 2

    def test_taxon_stripped(self, metaphlan_file: Path):
        df = parse_metaphlan4(metaphlan_file)
        assert "Staphylococcus_aureus" in df["taxon"].values

    def test_tool_label(self, metaphlan_file: Path):
        df = parse_metaphlan4(metaphlan_file)
        assert (df["tool"] == "metaphlan4").all()

    def test_rel_abundance_numeric(self, metaphlan_file: Path):
        df = parse_metaphlan4(metaphlan_file)
        assert pd.api.types.is_float_dtype(df["rel_abundance"])


# ── merge_abundance ───────────────────────────────────────────────────────────

class TestMergeAbundance:
    def test_two_samples_wide(self, bracken_file: Path, bracken_file2: Path):
        merged = merge_abundance([bracken_file, bracken_file2])
        assert "taxon" in merged.columns
        assert any("SRR001" in c for c in merged.columns)
        assert any("SRR002" in c for c in merged.columns)

    def test_all_taxa_present(self, bracken_file: Path, bracken_file2: Path):
        merged = merge_abundance([bracken_file, bracken_file2])
        taxa = set(merged["taxon"])
        assert "Staphylococcus aureus" in taxa

    def test_mixed_tools(self, bracken_file: Path, metaphlan_file: Path):
        merged = merge_abundance([bracken_file, metaphlan_file])
        cols = list(merged.columns)
        assert any("bracken" in c for c in cols)
        assert any("metaphlan4" in c for c in cols)

    def test_empty_files_raises(self, tmp_path: Path):
        empty = tmp_path / "unknown.txt"
        empty.write_text("")
        with pytest.raises(RuntimeError, match="No valid abundance files"):
            merge_abundance([empty])


# ── merge_strains ─────────────────────────────────────────────────────────────

class TestMergeStrains:
    def test_empty_list_returns_empty_df(self):
        df = merge_strains([])
        assert df.empty

    def test_valid_tsv(self, tmp_path: Path):
        f = tmp_path / "SRR001_strainphlan.tsv"
        f.write_text("clade\tsubstitution_rate\nBacteroides_fragilis\t0.001\n")
        df = merge_strains([f])
        assert "clade" in df.columns
        assert len(df) == 1
