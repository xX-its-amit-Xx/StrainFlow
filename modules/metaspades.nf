// metaSPAdes — high-quality metagenome assembly (optional; slower, higher contiguity)
// Image: quay.io/biocontainers/spades:3.15.5--h95f258a_1
// Enabled with --assembler metaspades

process METASPADES {
    tag          "$meta.id"
    label        'xlarge'
    publishDir   "${params.outdir}/assembly/metaspades/${meta.id}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/spades:3.15.5--h95f258a_1'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.contigs.fa.gz"), emit: contigs
    tuple val(meta), path("${meta.id}.scaffolds.fa.gz"), emit: scaffolds
    tuple val(meta), path("${meta.id}.spades.log"),      emit: log

    script:
    def memory_gb = task.memory.toGiga()
    """
    spades.py \\
        --meta \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -o spades_out \\
        --threads ${task.cpus} \\
        --memory ${memory_gb} \\
        2>&1 | tee ${meta.id}.spades.log

    cp spades_out/contigs.fasta  ${meta.id}.contigs.fa
    cp spades_out/scaffolds.fasta ${meta.id}.scaffolds.fa
    gzip ${meta.id}.contigs.fa ${meta.id}.scaffolds.fa
    """
}
