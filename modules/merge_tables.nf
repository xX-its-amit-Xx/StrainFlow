// Merge per-sample tables → combined TSV + Parquet analysis-ready artifacts
// Uses the bin/merge_tables.py helper script

process MERGE_TABLES {
    label        'small'
    publishDir   "${params.outdir}/merged", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/pandas:2.1.4--py310hb2f4e1b_0'

    input:
    path abundance_files    // Bracken + MetaPhlAn4 profiles, collected
    path strain_files       // StrainPhlAn / inStrain TSVs, collected

    output:
    path "strainflow_abundance.tsv",     emit: abundance_tsv
    path "strainflow_abundance.parquet", emit: abundance_parquet
    path "strainflow_strains.tsv",       emit: strains_tsv
    path "strainflow_strains.parquet",   emit: strains_parquet

    script:
    """
    python3 ${projectDir}/bin/merge_tables.py \\
        --abundance-files ${abundance_files} \\
        --strain-files    ${strain_files} \\
        --out-prefix      strainflow
    """
}
