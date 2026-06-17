// Kraken2 — k-mer-based taxonomic classification
// Image: staphb/kraken2:2.1.3

process KRAKEN2 {
    tag          "$meta.id"
    label        'large'
    publishDir   "${params.outdir}/kraken2/${meta.id}", mode: params.publish_dir_mode

    container 'staphb/kraken2:2.1.3'

    input:
    tuple val(meta), path(reads)
    path  kraken2_db

    output:
    tuple val(meta), path("${meta.id}.kraken2.report.txt"),  emit: report
    tuple val(meta), path("${meta.id}.kraken2.output.txt"),  emit: output

    script:
    """
    kraken2 \\
        --db ${kraken2_db} \\
        --paired \\
        --threads ${task.cpus} \\
        --report ${meta.id}.kraken2.report.txt \\
        --output ${meta.id}.kraken2.output.txt \\
        --gzip-compressed \\
        --confidence 0.1 \\
        ${reads[0]} ${reads[1]}
    """
}
