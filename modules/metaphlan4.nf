// MetaPhlAn4 — marker-gene-based taxonomic profiling
// Image: biobakery/metaphlan:4.1.1
// NOTE: MetaPhlAn4 uses clade-specific marker genes (not k-mers), enabling
// strain-level resolution that Kraken2/Bracken cannot provide.

process METAPHLAN4 {
    tag          "$meta.id"
    label        'medium'
    publishDir   "${params.outdir}/metaphlan4/${meta.id}", mode: params.publish_dir_mode

    container 'biobakery/metaphlan:4.1.1'

    input:
    tuple val(meta), path(reads)
    path  metaphlan_db

    output:
    tuple val(meta), path("${meta.id}.metaphlan4.txt"),    emit: profile
    tuple val(meta), path("${meta.id}.bowtie2.bz2"),       emit: bowtie2_out   // needed by StrainPhlAn
    tuple val(meta), path("${meta.id}.sam.bz2"),            emit: sam           // needed by StrainPhlAn

    script:
    """
    metaphlan \\
        ${reads[0]},${reads[1]} \\
        --bowtie2db ${metaphlan_db} \\
        --index latest \\
        --input_type fastq \\
        --nproc ${task.cpus} \\
        --output_file ${meta.id}.metaphlan4.txt \\
        --bowtie2out  ${meta.id}.bowtie2.bz2 \\
        --samout      ${meta.id}.sam.bz2 \\
        -t rel_ab_w_read_stats
    """
}
