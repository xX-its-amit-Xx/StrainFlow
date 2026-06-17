// CheckM — MAG completeness, contamination, and strain heterogeneity
// Image: quay.io/biocontainers/checkm-genome:1.2.2--pyhdfd78af_1

process CHECKM {
    tag          "$meta.id"
    label        'large'
    publishDir   "${params.outdir}/binning/checkm/${meta.id}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/checkm-genome:1.2.2--pyhdfd78af_1'

    input:
    tuple val(meta), path(bins_dir)

    output:
    tuple val(meta), path("${meta.id}_checkm/"),                       emit: results_dir
    tuple val(meta), path("${meta.id}_checkm.qa.tsv"),                 emit: tsv
    tuple val(meta), path("${meta.id}_checkm.lineage_wf.log"),         emit: log

    script:
    """
    # Decompress bins for CheckM
    mkdir -p bins_fa
    for f in ${bins_dir}/*.fa.gz; do
        gunzip -c "\$f" > bins_fa/\$(basename \$f .gz)
    done

    checkm lineage_wf \\
        bins_fa \\
        ${meta.id}_checkm \\
        --tab_table \\
        -f ${meta.id}_checkm.qa.tsv \\
        -t ${task.cpus} \\
        -x fa \\
        2>&1 | tee ${meta.id}_checkm.lineage_wf.log
    """
}
