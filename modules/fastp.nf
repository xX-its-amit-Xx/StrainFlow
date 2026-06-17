// fastp — adapter trimming, quality filtering, per-base correction
// Image: quay.io/biocontainers/fastp:0.23.4--h5f740d0_0

process FASTP {
    tag          "$meta.id"
    label        'small'
    publishDir   "${params.outdir}/fastp/${meta.id}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/fastp:0.23.4--h5f740d0_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_R{1,2}_trimmed.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}.fastp.json"),               emit: json
    tuple val(meta), path("${meta.id}.fastp.html"),               emit: html

    script:
    """
    fastp \\
        --in1  ${reads[0]} \\
        --in2  ${reads[1]} \\
        --out1 ${meta.id}_R1_trimmed.fastq.gz \\
        --out2 ${meta.id}_R2_trimmed.fastq.gz \\
        --json ${meta.id}.fastp.json \\
        --html ${meta.id}.fastp.html \\
        --thread ${task.cpus} \\
        --detect_adapter_for_pe \\
        --qualified_quality_phred 20 \\
        --length_required 50 \\
        --correction \\
        --cut_right \\
        --cut_right_window_size 4 \\
        --cut_right_mean_quality 20
    """
}
