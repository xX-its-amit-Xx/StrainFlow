# Test Data

This directory contains minimal test fixtures for running `nextflow run . -profile test`.

## Generating test reads

The test FASTQ files are 1000-read subsamples of real public data.
They are generated with:

```bash
# Install seqtk
conda install -c bioconda seqtk

# Subsample SRR21038798 (skin microbiome) to 1000 reads
seqtk sample -s 42 SRR21038798_1.fastq.gz 1000 | gzip > data/test/reads/test_sample_1_R1.fastq.gz
seqtk sample -s 42 SRR21038798_2.fastq.gz 1000 | gzip > data/test/reads/test_sample_1_R2.fastq.gz

# Subsample SRR21038799
seqtk sample -s 42 SRR21038799_1.fastq.gz 1000 | gzip > data/test/reads/test_sample_2_R1.fastq.gz
seqtk sample -s 42 SRR21038799_2.fastq.gz 1000 | gzip > data/test/reads/test_sample_2_R2.fastq.gz
```

## Mini reference databases

For CI speed, the test profile uses tiny mock databases:
- `refs/GRCh38_chr22_mini/` — chr22 only (bowtie2 index)
- `refs/kraken2_mini/`       — Standard-8 database (8 GB, sufficient for CI)
- `refs/metaphlan_mini/`     — MetaPhlAn4 SGB markers for common skin taxa

These are not committed to the repo (>1 GB); the CI workflow downloads them
from a cached S3 bucket during the `nextflow-test` job.
