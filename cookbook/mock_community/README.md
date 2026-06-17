# Cookbook Example B — Synthetic Mock Community (Zymo / CAMI)

**Purpose:** Demonstrate strain-resolution accuracy against a known ground truth.

Two mock communities are documented here:

---

## Mock A — Zymo D6305 (10-species mock)

**Product:** ZymoBIOMICS Microbial Community Standard (D6305)
**SRA accession:** SRR8359173 (Zymo-GridION-EVEN — Illumina reads)

This is a commercially available mock community with 8 bacteria and 2 fungi at
defined concentrations. Because exact reference genomes are known, we can measure
precision/recall of strain detection.

### Expected composition (Illumina theoretical)

| Species | Expected relative abundance |
|---------|---------------------------|
| *Pseudomonas aeruginosa* | 12.1% |
| *Escherichia coli* | 12.1% |
| *Salmonella enterica* | 12.1% |
| *Limosilactobacillus fermentati* | 12.1% |
| *Enterococcus faecalis* | 12.1% |
| *Staphylococcus aureus* | 12.1% |
| *Listeria monocytogenes* | 12.1% |
| *Bacillus subtilis* | 12.1% |
| *Saccharomyces cerevisiae* | 2.0% |
| *Cryptococcus neoformans* | 2.0% |

### Fetch data

```bash
prefetch SRR8359173
fasterq-dump SRR8359173.sra --split-files --threads 8
gzip SRR8359173_1.fastq SRR8359173_2.fastq
mv SRR8359173_1.fastq.gz zymo_mock_R1.fastq.gz
mv SRR8359173_2.fastq.gz zymo_mock_R2.fastq.gz
```

### Samplesheet

```csv
sample,fastq_1,fastq_2
zymo_mock,zymo_mock_R1.fastq.gz,zymo_mock_R2.fastq.gz
```

### Run StrainFlow

```bash
nextflow run xX-its-amit-Xx/StrainFlow \
    -profile local \
    --input samplesheet_zymo.csv \
    --outdir results/zymo_mock \
    --strainphlan_clades "t__SGB7975,t__SGB10068,t__SGB8060" \
    -params-file params_zymo.yaml
```

### Accuracy validation

```bash
# Compare detected abundances vs. expected (ground truth)
python3 bin/validate_mock.py \
    --detected  results/zymo_mock/merged/strainflow_abundance.tsv \
    --expected  cookbook/mock_community/zymo_expected.tsv \
    --output    cookbook/mock_community/accuracy_report.tsv
```

Expected accuracy targets (from literature):
- Bracken species-level: Spearman r > 0.95 vs. expected abundance
- MetaPhlAn4 species recall: ≥ 7/8 bacteria detected (fungi excluded, no marker DB)
- StrainPhlAn: correctly places each species in a single-strain cluster (no spurious splits)

---

## Mock B — CAMI2 Mouse Gut (gold-standard strain metagenome)

**Dataset:** CAMI2 challenge — mouse gut toy dataset
**DOI:** https://doi.org/10.1038/s41592-022-01431-4
**Files available at:** https://data.cami-challenge.org/participate

The CAMI2 mouse gut dataset contains simulated reads from 791 genomes (including
multiple strains of the same species), making it the ideal strain-level ground truth.

### Fetch data

```bash
# CAMI2 provides direct download links; no SRA registration needed
wget https://openstack.cebitec.uni-bielefeld.de:8080/swift/v1/CAMI_II_MOUSE_GUT/2017.12.29_11.37.26_sample_0/reads/anonymous_reads.fq.gz

# Split into R1/R2 (interleaved FASTQ)
reformat.sh in=anonymous_reads.fq.gz \
    out1=cami2_mouse_R1.fastq.gz \
    out2=cami2_mouse_R2.fastq.gz
```

### Ground-truth evaluation

The CAMI2 challenge provides:
- `gs_taxonomic_profile.txt` — true species abundances at each taxonomic level
- `genome_distributions/` — per-genome read counts for strain-level ground truth

```bash
# After pipeline run, evaluate with OPAL (community benchmark tool)
pip install cami-opal
opal.py -g gs_taxonomic_profile.txt \
        results/cami2_mouse/bracken/*.bracken.S.txt \
        results/cami2_mouse/metaphlan4/*.metaphlan4.txt \
        -o cami2_benchmark_report/
```

---

## Notes

- **Why both mocks?** Zymo D6305 has wet-lab-validated compositions (most realistic),
  while CAMI2 provides strain-level ground truth impossible to get from real data.
- **Why no real outputs committed?** Bioinformatics databases (Kraken2 ~70 GB, MetaPhlAn4
  ~15 GB) are too large for CI. The cookbook documents exact commands + expected metrics;
  actual run artifacts are available in the [StrainFlow v1.0.0 release](https://github.com/xX-its-amit-Xx/StrainFlow/releases) as attachments.
