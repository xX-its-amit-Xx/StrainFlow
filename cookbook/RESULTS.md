# StrainFlow Cookbook — Results Walkthrough

This document walks through the outputs of both cookbook examples, explaining what each
file means and how to interpret the results.

---

## Example A — Human Skin Microbiome (Byrd et al. 2018)

### QC summary (fastp + FastQC)

After trimming and host removal, expect:
- **~70–85% of reads** map to GRCh38 (human skin metagenomes are read-rich for host)
- **~15–30% microbial reads** remain — enough for robust profiling
- Q30 rate post-trimming: ≥ 85%
- Mean read length after trimming: 130–148 bp

The MultiQC report (`results/multiqc/multiqc_report.html`) integrates all these
statistics into a single interactive HTML dashboard. Open it in any browser.

```
Key MultiQC sections:
  ├── FastQC (pre-trim)  — per-base quality, GC content, adapter content
  ├── fastp              — trimming summary, duplication rate
  ├── FastQC (post-trim) — confirms adapter removal
  └── Kraken2            — classified read counts per sample
```

### Taxonomic profiles

**Bracken** (`results/merged/strainflow_abundance.tsv`, columns `*_bracken`):

Expected dominant species for AD skin:
| Species | AD patients | Healthy controls |
|---------|------------|-----------------|
| *S. aureus* | ~35–60% | <5% |
| *S. epidermidis* | ~10–25% | ~30–50% |
| *C. acnes* | ~5–15% | ~15–30% |
| *Malassezia restricta* | ~5–10% | ~5–15% |

**MetaPhlAn4** (`results/merged/strainflow_abundance.tsv`, columns `*_metaphlan4`):
MetaPhlAn4 provides complementary depth — it detects fewer taxa (marker-gene limited)
but with very high precision (low false-positive rate). When both tools agree on a taxon,
high confidence.

### Strain-level resolution

**StrainPhlAn** (`results/strainphlan/t__SGB7975/t__SGB7975.tre`):

The Newick tree for *S. aureus* (SGB7975) clusters samples by strain. In the Byrd et al.
dataset, AD patients often carry a single dominant *S. aureus* strain that is distinct
from healthy control strains. This is visible as:
- AD samples clustering together in the phylogenetic tree
- Short branch lengths within AD cluster (clonal expansion)
- Long branch separating AD from HC strains

```
        ┌─── skin_AD_01
   ─────┤
        └─── skin_AD_02        ← Same clone; short branches
   
   ─────────────────────────── skin_HC_01  ← Distinct strain
```

**inStrain** (`results/instrain/compare/strain_clusters.tsv`):

inStrain provides within-host microdiversity metrics:
- **popANI**: population-level average nucleotide identity; >99.999% = same strain
- **conANI**: consensus-level ANI; >99% = same species
- Sites with >5% minor allele frequency indicate mixed-strain infection

For *S. aureus* in AD patients, expect:
- Within-patient popANI > 99.99% (one dominant clone)
- Between-AD-patient popANI can vary (community acquisition)

### MAG statistics (CheckM)

`results/binning/checkm/*.qa.tsv` contains:

| Metric | Good MAG (HQ) | Medium quality |
|--------|--------------|----------------|
| Completeness | ≥ 90% | 50–90% |
| Contamination | ≤ 5% | 5–10% |
| N50 | > 100 kb | > 20 kb |

For skin metagenomes, expect 3–8 MAGs per sample. *S. aureus* and *S. epidermidis*
typically yield the highest-quality bins due to their abundance.

### Functional profiling (HUMAnN3)

`results/merged/strainflow_abundance.tsv` also contains pathway abundances.

Expected differences between AD and healthy:
- AD: enriched in *S. aureus* virulence pathways (PWY-5100: pyruvate oxidation)
- HC: enriched in *C. acnes* lipase pathways (skin lipid metabolism)

---

## Example B — Zymo Mock Community

### Accuracy metrics

After running StrainFlow on the Zymo D6305 mock (SRR8359173), expect:

**Bracken accuracy:**
- Spearman correlation with expected: r = 0.94–0.97
- All 8 bacteria detected at > 1% abundance
- *S. cerevisiae* and *C. neoformans* may be missed (no fungal Kraken DB in default run)

**MetaPhlAn4 accuracy:**
- 7/8 bacterial species detected (marker database may lack some strains)
- Lower false-positive rate than Kraken2 — if MetaPhlAn4 detects it, it's there

**StrainPhlAn validation:**
- Single-strain clusters for each detected species (no spurious splits)
- Branch lengths reflect known taxonomic distance

```
Example output — t__SGB7975 (S. aureus in mock):
  Single sample, single strain → trivial tree, confirms single-strain community
```

### CAMI2 strain-level validation

On the CAMI2 mouse gut dataset, literature benchmarks for similar pipelines show:
- L1-norm error (abundance estimation): < 0.3 for Bracken at species level
- True positive rate for strains present at > 1%: > 85%
- StrainPhlAn correctly resolves clades present at > 0.1% relative abundance

> **Note on committed outputs:** Full MultiQC HTML reports, abundance tables, and
> CheckM summaries from production runs on real compute are attached to the
> [StrainFlow v1.0.0 GitHub Release](https://github.com/xX-its-amit-Xx/StrainFlow/releases/tag/v1.0.0).
> They are not committed to the main repository due to file size (~150 MB for MultiQC + tables).
> The pipeline code and all tool configurations are fully deterministic — running
> with the same database versions will reproduce these outputs exactly.

---

## Interpreting the merged tables

### `strainflow_abundance.tsv`

Wide-format table; rows = taxa, columns = `{sample}_{tool}`:

```
taxon                    skin_AD_01_bracken  skin_AD_01_metaphlan4  skin_HC_01_bracken ...
Staphylococcus aureus    0.52               48.3                   0.02
Cutibacterium acnes      0.15               14.1                   0.31
```

**Units:**
- Bracken: fraction of classified reads (0–1)
- MetaPhlAn4: estimated relative abundance (0–100)

### `strainflow_strains.tsv`

Long-format; includes StrainPhlAn substitution rates and inStrain popANI values:

```
sample       clade              tool          metric        value
skin_AD_01   t__SGB7975         strainphlan   subst_rate    0.00023
skin_AD_01   t__SGB7975         instrain      popANI        0.99997
```

### Loading the Parquet files

```python
import pandas as pd

abundance = pd.read_parquet("strainflow_abundance.parquet")
strains   = pd.read_parquet("strainflow_strains.parquet")

# Get S. aureus abundance across all samples
saur = abundance[abundance["taxon"].str.contains("aureus")]
print(saur.T)
```

---

## Using the MCP tool

After a run, query strain abundances from any Claude agent:

```bash
# Start the MCP server
python3 bin/mcp_strain_query.py \
    --abundance results/merged/strainflow_abundance.parquet \
    --strains   results/merged/strainflow_strains.parquet
```

Configure in Claude Code (`~/.claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "strainflow": {
      "command": "python3",
      "args": [
        "/path/to/StrainFlow/bin/mcp_strain_query.py",
        "--abundance", "/path/to/results/strainflow_abundance.parquet",
        "--strains",   "/path/to/results/strainflow_strains.parquet"
      ]
    }
  }
}
```

Then in Claude: *"Give me strain abundances for sample skin_AD_01"*
