// inStrain — read-level microdiversity, SNV profiling, population genetics
// Image: quay.io/biocontainers/instrain:1.8.0--pyhdfd78af_0
//
// inStrain works at the read level, providing per-site allele frequencies,
// linkage disequilibrium, and strain-sharing statistics across samples.
// It complements StrainPhlAn (marker-gene trees) with population-genomic resolution.
//
// WORKFLOW:
//   1. Map trimmed reads against the inStrain reference genome database
//   2. Run inStrain profile to generate per-sample SNV profiles
//   3. (optional) inStrain compare for cross-sample strain sharing

process INSTRAIN_PROFILE {
    tag          "$meta.id"
    label        'large'
    publishDir   "${params.outdir}/instrain/${meta.id}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/instrain:1.8.0--pyhdfd78af_0'

    input:
    tuple val(meta), path(reads)
    path  instrain_db

    output:
    tuple val(meta), path("${meta.id}_IS/"),          emit: profile_dir
    tuple val(meta), path("${meta.id}_IS/*.tsv"),     emit: tsv
    tuple val(meta), path("${meta.id}_IS/log/"),      emit: log

    script:
    """
    # Step 1: Map reads to inStrain reference database (Bowtie2)
    bowtie2 \\
        -x ${instrain_db} \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        -p ${task.cpus} \\
        --no-unal \\
    | samtools sort -@ ${task.cpus} -o ${meta.id}.sorted.bam

    samtools index ${meta.id}.sorted.bam

    # Step 2: inStrain profile
    inStrain profile \\
        ${meta.id}.sorted.bam \\
        ${instrain_db}.fasta \\
        -o ${meta.id}_IS \\
        -p ${task.cpus} \\
        --database_mode \\
        --min_cov 5 \\
        --min_freq 0.05
    """
}

process INSTRAIN_COMPARE {
    tag          "compare"
    label        'large'
    publishDir   "${params.outdir}/instrain/compare", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/instrain:1.8.0--pyhdfd78af_0'

    input:
    path profile_dirs   // all _IS/ directories, collected
    path instrain_db

    output:
    path "strain_compare/",             emit: compare_dir
    path "strain_compare/*.tsv",        emit: tsv
    path "strain_compare/strain_clusters.tsv", emit: clusters

    script:
    """
    inStrain compare \\
        -i ${profile_dirs} \\
        -o strain_compare \\
        -p ${task.cpus} \\
        --database_mode
    """
}
