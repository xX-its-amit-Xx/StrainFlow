// Bowtie2 host-read removal — align to GRCh38, keep only unmapped reads
// Image: quay.io/biocontainers/bowtie2:2.5.3--py310h8d7afc0_0
// Paired with samtools for BAM → unmapped-reads extraction

process BOWTIE2_HOST_REMOVAL {
    tag          "$meta.id"
    label        'medium'
    publishDir   "${params.outdir}/host_removal/${meta.id}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/bowtie2:2.5.3--py310h8d7afc0_0'

    input:
    tuple val(meta), path(reads)
    path  host_index                // directory containing bowtie2 index files

    output:
    tuple val(meta), path("${meta.id}_host_removed_R{1,2}.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}_host_removal.log"),              emit: log

    script:
    def index_prefix = "${host_index}/${host_index.name}"
    """
    bowtie2 \\
        -x ${params.host_index} \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -p ${task.cpus} \\
        --very-sensitive \\
        2>${meta.id}_host_removal.log \\
    | samtools view -bS -f 12 -F 256 \\
    | samtools sort -n -@ ${task.cpus} \\
    | samtools fastq \\
        -1 ${meta.id}_host_removed_R1.fastq.gz \\
        -2 ${meta.id}_host_removed_R2.fastq.gz \\
        -0 /dev/null \\
        -s /dev/null \\
        -n
    """
}
