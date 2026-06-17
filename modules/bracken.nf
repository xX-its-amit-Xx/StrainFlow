// Bracken — Bayesian re-estimation of Kraken2 abundances at species level
// Image: staphb/bracken:2.9

process BRACKEN {
    tag          "$meta.id"
    label        'small'
    publishDir   "${params.outdir}/bracken/${meta.id}", mode: params.publish_dir_mode

    container 'staphb/bracken:2.9'

    input:
    tuple val(meta), path(kraken2_report)
    path  kraken2_db

    output:
    tuple val(meta), path("${meta.id}.bracken.${params.bracken_level}.txt"), emit: report
    tuple val(meta), path("${meta.id}.bracken.${params.bracken_level}.report.txt"), emit: kreport

    script:
    """
    bracken \\
        -d ${kraken2_db} \\
        -i ${kraken2_report} \\
        -o ${meta.id}.bracken.${params.bracken_level}.txt \\
        -w ${meta.id}.bracken.${params.bracken_level}.report.txt \\
        -r ${params.bracken_length} \\
        -l ${params.bracken_level} \\
        -t 10
    """
}
