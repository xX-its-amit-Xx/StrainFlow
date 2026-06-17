# Cookbook Example A — Human Skin Microbiome

**Dataset:** Byrd et al. 2018 "Staphylococcus aureus and Staphylococcus epidermidis
strain diversity underlying pediatric atopic dermatitis" (PRJNA420244)

## SRA accessions used

| Sample ID | SRA Accession | Description |
|-----------|---------------|-------------|
| skin_AD_01 | SRR6355498 | Atopic dermatitis patient — antecubital fossa |
| skin_AD_02 | SRR6355499 | Atopic dermatitis patient — antecubital fossa |
| skin_HC_01 | SRR6355506 | Healthy control — antecubital fossa |
| skin_HC_02 | SRR6355507 | Healthy control — antecubital fossa |

These are publicly available shotgun metagenomics (150 bp paired-end, Illumina HiSeq 2500)
from human skin. Published in Science (2018). DOI: 10.1126/science.aap8385

## Fetch the data

```bash
# Install SRA Toolkit
conda install -c bioconda sra-tools=3.1.0

# Download and convert to FASTQ (prefetch + fasterq-dump is faster than fastq-dump)
ACCESSIONS=(SRR6355498 SRR6355499 SRR6355506 SRR6355507)
NAMES=(skin_AD_01 skin_AD_02 skin_HC_01 skin_HC_02)

for i in "${!ACCESSIONS[@]}"; do
    acc="${ACCESSIONS[$i]}"
    name="${NAMES[$i]}"
    prefetch $acc --output-directory raw_data/
    fasterq-dump raw_data/$acc/$acc.sra \
        --split-files \
        --outdir raw_data/ \
        --threads 8
    gzip -1 raw_data/${acc}_1.fastq && mv raw_data/${acc}_1.fastq.gz raw_data/${name}_R1.fastq.gz
    gzip -1 raw_data/${acc}_2.fastq && mv raw_data/${acc}_2.fastq.gz raw_data/${name}_R2.fastq.gz
done
```

## Samplesheet

```csv
sample,fastq_1,fastq_2
skin_AD_01,raw_data/skin_AD_01_R1.fastq.gz,raw_data/skin_AD_01_R2.fastq.gz
skin_AD_02,raw_data/skin_AD_02_R1.fastq.gz,raw_data/skin_AD_02_R2.fastq.gz
skin_HC_01,raw_data/skin_HC_01_R1.fastq.gz,raw_data/skin_HC_01_R2.fastq.gz
skin_HC_02,raw_data/skin_HC_02_R1.fastq.gz,raw_data/skin_HC_02_R2.fastq.gz
```

## Run StrainFlow

```bash
# Local (Docker required)
nextflow run xX-its-amit-Xx/StrainFlow \
    -profile local \
    --input samplesheet.csv \
    --outdir results/skin_microbiome \
    -params-file params_skin.yaml

# AWS Batch
nextflow run xX-its-amit-Xx/StrainFlow \
    -profile aws \
    --input s3://my-bucket/samplesheet.csv \
    --outdir s3://my-bucket/results/skin_microbiome \
    -params-file params_skin.yaml
```

## params_skin.yaml

```yaml
host_index:          "/data/refs/GRCh38/GRCh38_noalt_bowtie2"
kraken2_db:          "/data/refs/kraken2/k2_standard_20240605"
metaphlan_db:        "/data/refs/metaphlan/mpa_vJan21_CHOCOPhlAnSGB_202103"
instrain_db:         "/data/refs/instrain/MIDAS_v1.3.2.idb"
humann3_nt_db:       "/data/refs/humann3/chocophlan"
humann3_prot_db:     "/data/refs/humann3/uniref90_annotated_v201901"
strainphlan_clades:  "t__SGB7975,t__SGB7980"  # S. aureus and S. epidermidis SGBs
assembler:           "megahit"
enable_gtdbtk:       false
```

## Expected outputs

```
results/skin_microbiome/
├── fastp/                          # Trimming reports
├── fastqc/                         # Pre/post-trim FastQC
├── host_removal/                   # % human reads removed (~70-85% for skin)
├── kraken2/                        # Taxonomic classification
├── bracken/                        # Abundance re-estimation
├── metaphlan4/                     # Marker-gene abundance profiles
├── strainphlan/
│   ├── t__SGB7975/                 # S. aureus strain tree
│   │   ├── t__SGB7975.tre          # Newick phylogenetic tree
│   │   └── t__SGB7975.aln          # Multiple sequence alignment
│   └── t__SGB7980/                 # S. epidermidis strain tree
├── instrain/
│   ├── skin_AD_01_IS/              # Per-sample inStrain profile
│   └── compare/                    # Cross-sample strain sharing
│       └── strain_clusters.tsv
├── assembly/megahit/               # Assembled contigs
├── binning/
│   ├── metabat2/                   # MAG bins
│   └── checkm/                     # MAG QC
├── functional/humann3/             # Pathway abundances
├── multiqc/multiqc_report.html     # Aggregate QC report
└── merged/
    ├── strainflow_abundance.tsv     # Combined abundance table
    ├── strainflow_abundance.parquet
    ├── strainflow_strains.tsv       # Combined strain table
    └── strainflow_strains.parquet
```

## Biological interpretation

This dataset is ideal for StrainFlow because:
1. **Known biology:** AD patients have significantly elevated *S. aureus* loads
2. **Strain resolution matters:** Different *S. aureus* strains have distinct virulence profiles;
   StrainPhlAn's phylogenetic tree reveals whether AD patients share strains (nosocomial?)
   or carry distinct community acquisitions
3. **inStrain complementarity:** SNV profiles quantify within-host *S. aureus* diversity
   that marker-gene approaches cannot detect

## Notes on data access

All accessions are publicly available without dbGaP authorization.
The Byrd et al. dataset is not human-subject-restricted (skin metagenomes, no germline data).
Verify at: https://www.ncbi.nlm.nih.gov/sra/SRR6355498
