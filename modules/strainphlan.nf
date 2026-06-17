// StrainPhlAn — strain-level phylogenetic analysis from MetaPhlAn4 markers
// Part of the MetaPhlAn4 package; uses the same Docker image.
// Image: biobakery/metaphlan:4.1.1
//
// WORKFLOW:
//   1. sample2markers: extract consensus markers from per-sample SAM/BZ2 files
//   2. extract_markers: pull reference marker sequences for each detected clade
//   3. strainphlan: build multi-sequence alignment + phylogenetic tree per clade

process STRAINPHLAN_SAMPLE2MARKERS {
    tag          "$meta.id"
    label        'medium'
    publishDir   "${params.outdir}/strainphlan/markers", mode: params.publish_dir_mode

    container 'biobakery/metaphlan:4.1.1'

    input:
    tuple val(meta), path(sam_bz2)
    path  metaphlan_db

    output:
    tuple val(meta), path("${meta.id}.pkl"), emit: markers

    script:
    """
    sample2markers.py \\
        -i ${sam_bz2} \\
        -d ${metaphlan_db} \\
        -o . \\
        --nprocs ${task.cpus}
    mv *.pkl ${meta.id}.pkl
    """
}

process STRAINPHLAN_EXTRACT_MARKERS {
    tag          "$clade"
    label        'small'
    publishDir   "${params.outdir}/strainphlan/clade_markers", mode: params.publish_dir_mode

    container 'biobakery/metaphlan:4.1.1'

    input:
    val  clade
    path metaphlan_db

    output:
    tuple val(clade), path("${clade}.fna"), emit: fna

    script:
    """
    extract_markers.py \\
        -c ${clade} \\
        -d ${metaphlan_db} \\
        -o .
    """
}

process STRAINPHLAN {
    tag          "$clade"
    label        'large'
    publishDir   "${params.outdir}/strainphlan/${clade}", mode: params.publish_dir_mode

    container 'biobakery/metaphlan:4.1.1'

    input:
    val  clade
    path sample_markers          // all *.pkl files, collected
    path clade_fna
    path metaphlan_db

    output:
    tuple val(clade), path("${clade}/*.tre"),              emit: tree
    tuple val(meta),  path("${clade}/*.aln"),              emit: alignment
    tuple val(meta),  path("${clade}/strainphlan.tsv"),    emit: tsv

    script:
    def clades_arg = params.strainphlan_clades ? "-c ${params.strainphlan_clades}" : "-c ${clade}"
    """
    mkdir -p ${clade}
    strainphlan \\
        -s ${sample_markers} \\
        -m ${clade_fna} \\
        -d ${metaphlan_db} \\
        -o ${clade} \\
        -n ${task.cpus} \\
        ${clades_arg} \\
        --mutation_rates \\
        --phylophlan_mode accurate
    """
}
