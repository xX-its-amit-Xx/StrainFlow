// GTDB-Tk — taxonomy assignment for MAGs using GTDB reference tree
// Image: ecogenomics/gtdbtk:2.4.0
// OPTIONAL: enabled with --enable_gtdbtk true; DB is ~75 GB
// Reference: Parks et al. 2022 (Nature Biotechnology)

process GTDBTK {
    tag          "$meta.id"
    label        'xlarge'
    publishDir   "${params.outdir}/binning/gtdbtk/${meta.id}", mode: params.publish_dir_mode

    container 'ecogenomics/gtdbtk:2.4.0'

    when:
    params.enable_gtdbtk

    input:
    tuple val(meta), path(bins_dir)
    path  gtdbtk_db

    output:
    tuple val(meta), path("${meta.id}_gtdbtk/"),                              emit: results_dir
    tuple val(meta), path("${meta.id}_gtdbtk/*.summary.tsv"),                 emit: summary
    tuple val(meta), path("${meta.id}_gtdbtk/gtdbtk.log"),                   emit: log

    script:
    """
    export GTDBTK_DATA_PATH=${gtdbtk_db}

    mkdir -p bins_fa
    for f in ${bins_dir}/*.fa.gz; do
        gunzip -c "\$f" > bins_fa/\$(basename \$f .gz)
    done

    gtdbtk classify_wf \\
        --genome_dir bins_fa \\
        --out_dir ${meta.id}_gtdbtk \\
        --cpus ${task.cpus} \\
        --extension fa \\
        --skip_ani_screen

    cp ${meta.id}_gtdbtk/gtdbtk.log ${meta.id}_gtdbtk/gtdbtk.log || true
    """
}
