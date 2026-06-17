# StrainFlow — Container Registry

All images are pinned to exact digest-reproducible versions. No `latest` tags are used.

| Module | Image | Version | Registry | Source |
|--------|-------|---------|----------|--------|
| FastQC | `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0` | 0.12.1 | BioContainers | [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) |
| fastp | `quay.io/biocontainers/fastp:0.23.4--h5f740d0_0` | 0.23.4 | BioContainers | [fastp](https://github.com/OpenGene/fastp) |
| Bowtie2 + samtools | `quay.io/biocontainers/bowtie2:2.5.3--py310h8d7afc0_0` | 2.5.3 | BioContainers | [bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/) |
| Kraken2 | `staphb/kraken2:2.1.3` | 2.1.3 | StaPH-B | [kraken2](https://ccb.jhu.edu/software/kraken2/) |
| Bracken | `staphb/bracken:2.9` | 2.9 | StaPH-B | [bracken](https://ccb.jhu.edu/software/bracken/) |
| MetaPhlAn4 + StrainPhlAn | `biobakery/metaphlan:4.1.1` | 4.1.1 | bioBakery | [metaphlan](https://github.com/biobakery/MetaPhlAn) |
| inStrain | `quay.io/biocontainers/instrain:1.8.0--pyhdfd78af_0` | 1.8.0 | BioContainers | [instrain](https://github.com/MrOlm/inStrain) |
| MEGAHIT | `quay.io/biocontainers/megahit:1.2.9--h5b5514e_4` | 1.2.9 | BioContainers | [megahit](https://github.com/voutcn/megahit) |
| metaSPAdes | `quay.io/biocontainers/spades:3.15.5--h95f258a_1` | 3.15.5 | BioContainers | [SPAdes](https://github.com/ablab/spades) |
| MetaBAT2 | `quay.io/biocontainers/metabat2:2.15--h4da6f23_2` | 2.15 | BioContainers | [metabat2](https://bitbucket.org/berkeleylab/metabat) |
| CheckM | `quay.io/biocontainers/checkm-genome:1.2.2--pyhdfd78af_1` | 1.2.2 | BioContainers | [checkm](https://github.com/Ecogenomics/CheckM) |
| GTDB-Tk | `ecogenomics/gtdbtk:2.4.0` | 2.4.0 | DockerHub | [gtdbtk](https://github.com/Ecogenomics/GTDBTk) |
| HUMAnN3 | `biobakery/humann:3.9` | 3.9 | bioBakery | [humann](https://github.com/biobakery/humann) |
| MultiQC | `quay.io/biocontainers/multiqc:1.22.3--pyhdfd78af_0` | 1.22.3 | BioContainers | [multiqc](https://multiqc.info/) |
| Pandas (merge_tables) | `quay.io/biocontainers/pandas:2.1.4--py310hb2f4e1b_0` | 2.1.4 | BioContainers | [pandas](https://pandas.pydata.org/) |
| Python (manifest) | `quay.io/biocontainers/python:3.11--hb4d6b87_2` | 3.11 | BioContainers | [python](https://python.org/) |

## Updating images

To update a pinned image:

1. Find the new tag on [BioContainers](https://biocontainers.pro/) or the tool's registry.
2. Update the `container` directive in the relevant `modules/*.nf` file.
3. Update the version in this table.
4. Open a PR — CI will validate the updated image.

## Verifying image digests

```bash
# Pull and inspect a specific image digest
docker pull quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0
docker inspect quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0 | jq '.[0].Id'
```

## BioContainers vs. StaPH-B vs. bioBakery

- **BioContainers** (`quay.io/biocontainers/*`): community-maintained, multi-arch, preferred for most tools.
- **StaPH-B** (`staphb/*`): US public health labs; includes Kraken2/Bracken with pre-configured environments.
- **bioBakery** (`biobakery/*`): Huttenhower Lab official images for MetaPhlAn4 and HUMAnN3; bundled with tool-specific databases paths.
