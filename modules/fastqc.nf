// FastQC — per-read quality assessment
// Image: quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0

process FASTQC {
    tag          "$meta.id"
    label        'small'
    publishDir   "${params.outdir}/fastqc/${meta.id}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip"),  emit: zip

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    fastqc \\
        --threads ${task.cpus} \\
        --outdir . \\
        ${reads}
    """
}
