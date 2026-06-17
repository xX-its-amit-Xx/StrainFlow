// MetaBAT2 — metagenomic binning to recover MAGs
// Image: quay.io/biocontainers/metabat2:2.15--h4da6f23_2
//
// MetaBAT2 uses tetranucleotide frequencies and depth-of-coverage to
// cluster contigs into putative genome bins (MAGs).

process METABAT2 {
    tag          "$meta.id"
    label        'medium'
    publishDir   "${params.outdir}/binning/metabat2/${meta.id}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/metabat2:2.15--h4da6f23_2'

    input:
    tuple val(meta), path(contigs)
    tuple val(meta), path(reads)    // for depth calculation

    output:
    tuple val(meta), path("bins/"),            emit: bins_dir
    tuple val(meta), path("bins/*.fa.gz"),     emit: bins
    tuple val(meta), path("${meta.id}.depth.txt"), emit: depth

    script:
    """
    # Decompress contigs if gzipped
    [[ ${contigs} == *.gz ]] && gunzip -c ${contigs} > contigs.fa || cp ${contigs} contigs.fa

    # Map reads back to assembly for coverage depth estimation
    bowtie2-build contigs.fa contigs_index --threads ${task.cpus}
    bowtie2 -x contigs_index -1 ${reads[0]} -2 ${reads[1]} \\
        -p ${task.cpus} --no-unal \\
    | samtools sort -@ ${task.cpus} -o ${meta.id}.sorted.bam
    samtools index ${meta.id}.sorted.bam

    # Calculate depth
    jgi_summarize_bam_contig_depths \\
        --outputDepth ${meta.id}.depth.txt \\
        ${meta.id}.sorted.bam

    # Bin contigs
    mkdir -p bins
    metabat2 \\
        -i contigs.fa \\
        -a ${meta.id}.depth.txt \\
        -o bins/${meta.id}_bin \\
        -t ${task.cpus} \\
        --minContig ${params.metabat2_min_contig} \\
        --minClsSize 200000 \\
        -v

    # Compress bins
    gzip bins/*.fa 2>/dev/null || true
    """
}
