#!/usr/bin/env nextflow
// StrainFlow — strain-resolved shotgun metagenomics pipeline
// License: GPL v3.0  |  https://github.com/xX-its-amit-Xx/StrainFlow

nextflow.enable.dsl = 2

// ── sub-workflow imports ──────────────────────────────────────────────────────
include { QC_WORKFLOW        } from './subworkflows/qc'
include { PROFILING_WORKFLOW } from './subworkflows/profiling'
include { ASSEMBLY_WORKFLOW  } from './subworkflows/assembly'
include { BINNING_WORKFLOW   } from './subworkflows/binning'
include { FUNCTIONAL_WORKFLOW} from './subworkflows/functional'

// ── standalone module imports ─────────────────────────────────────────────────
include { MULTIQC            } from './modules/multiqc'
include { MERGE_TABLES       } from './modules/merge_tables'
include { RUN_MANIFEST       } from './modules/run_manifest'

// ── parameter validation ──────────────────────────────────────────────────────
def validateParams() {
    if (!params.input) {
        error "Parameter --input (samplesheet CSV) is required."
    }
    if (params.enable_gtdbtk && !params.gtdbtk_db) {
        error "--gtdbtk_db must be set when --enable_gtdbtk is true."
    }
}

// ── samplesheet parsing ───────────────────────────────────────────────────────
def parseSamplesheet(csv) {
    Channel
        .fromPath(csv, checkIfExists: true)
        .splitCsv(header: true, strip: true)
        .map { row ->
            def meta = [id: row.sample, single_end: false]
            def reads = [
                file(row.fastq_1, checkIfExists: true),
                file(row.fastq_2, checkIfExists: true)
            ]
            [meta, reads]
        }
}

// ── main workflow ─────────────────────────────────────────────────────────────
workflow {
    validateParams()

    ch_reads = parseSamplesheet(params.input)

    // 1. QC + host removal
    QC_WORKFLOW(ch_reads)

    // 2. Taxonomic + strain profiling
    PROFILING_WORKFLOW(QC_WORKFLOW.out.clean_reads)

    // 3. Assembly (MEGAHIT default; metaSPAdes if --assembler metaspades)
    ASSEMBLY_WORKFLOW(QC_WORKFLOW.out.clean_reads)

    // 4. MAG binning + QC
    BINNING_WORKFLOW(
        ASSEMBLY_WORKFLOW.out.contigs,
        QC_WORKFLOW.out.clean_reads
    )

    // 5. Functional profiling (HUMAnN3)
    FUNCTIONAL_WORKFLOW(QC_WORKFLOW.out.clean_reads)

    // 6. Aggregate MultiQC report
    ch_multiqc_files = Channel.empty()
        .mix(QC_WORKFLOW.out.fastqc_zip)
        .mix(QC_WORKFLOW.out.fastp_json)
        .mix(PROFILING_WORKFLOW.out.kraken2_report)
        .mix(BINNING_WORKFLOW.out.checkm_tsv)
        .collect()

    MULTIQC(ch_multiqc_files)

    // 7. Merge per-sample tables into analysis-ready artefacts
    ch_abundance = PROFILING_WORKFLOW.out.bracken_report
        .mix(PROFILING_WORKFLOW.out.metaphlan_profile)
        .collect()

    MERGE_TABLES(ch_abundance, PROFILING_WORKFLOW.out.strain_profiles.collect())

    // 8. Provenance manifest
    RUN_MANIFEST(
        ch_reads.map { meta, _r -> meta.id }.collect(),
        workflow.manifest.version,
        workflow.commitId ?: 'unknown',
        params
    )
}

// ── on-complete summary ───────────────────────────────────────────────────────
workflow.onComplete {
    log.info """
    ╔══════════════════════════════════════════════════════════╗
    ║              StrainFlow — pipeline complete              ║
    ╠══════════════════════════════════════════════════════════╣
    ║  Status   : ${workflow.success ? 'SUCCESS' : 'FAILED'}
    ║  Duration : ${workflow.duration}
    ║  Results  : ${params.outdir}
    ╚══════════════════════════════════════════════════════════╝
    """.stripIndent()
}
