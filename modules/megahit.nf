// MEGAHIT — de novo metagenomic assembly (fast, memory-efficient)
// Image: quay.io/biocontainers/megahit:1.2.9--h5b5514e_4

process MEGAHIT {
    tag          "$meta.id"
    label        'large'
    publishDir   "${params.outdir}/assembly/megahit/${meta.id}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/megahit:1.2.9--h5b5514e_4'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.contigs.fa.gz"), emit: contigs
    tuple val(meta), path("${meta.id}.megahit.log"),   emit: log

    script:
    def memory_gb = task.memory.toGiga()
    """
    megahit \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -o megahit_out \\
        -t ${task.cpus} \\
        -m ${memory_gb}e9 \\
        --presets ${params.megahit_preset} \\
        --min-contig-len 500 \\
        2>&1 | tee ${meta.id}.megahit.log

    cp megahit_out/final.contigs.fa ${meta.id}.contigs.fa
    gzip ${meta.id}.contigs.fa
    """
}
