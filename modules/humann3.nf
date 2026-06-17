// HUMAnN3 — functional profiling: pathway + gene-family abundances
// Image: biobakery/humann:3.9
// Reference: Beghini et al. 2021 (eLife); Franzosa et al. 2018 (Nature Methods)
//
// HUMAnN3 produces:
//   - Gene families (UniRef90): transcript-level functional annotation
//   - Pathway abundances (MetaCyc): metabolic pathway coverage
//   - Pathway coverage: fraction of a pathway's genes detected

process HUMANN3 {
    tag          "$meta.id"
    label        'large'
    publishDir   "${params.outdir}/functional/humann3/${meta.id}", mode: params.publish_dir_mode

    container 'biobakery/humann:3.9'

    input:
    tuple val(meta), path(reads)
    path  nt_db
    path  prot_db

    output:
    tuple val(meta), path("${meta.id}_genefamilies.tsv"),      emit: genefamilies
    tuple val(meta), path("${meta.id}_pathabundance.tsv"),     emit: pathabundance
    tuple val(meta), path("${meta.id}_pathcoverage.tsv"),      emit: pathcoverage
    tuple val(meta), path("${meta.id}_humann3.log"),           emit: log

    script:
    """
    # Concatenate paired-end reads for HUMAnN3 input
    cat <(zcat ${reads[0]}) <(zcat ${reads[1]}) > ${meta.id}_combined.fastq

    humann \\
        --input  ${meta.id}_combined.fastq \\
        --output . \\
        --output-basename ${meta.id} \\
        --threads ${task.cpus} \\
        --nucleotide-database ${nt_db} \\
        --protein-database    ${prot_db} \\
        --search-mode uniref90 \\
        --memory-use maximum \\
        --log-level DEBUG \\
        2>&1 | tee ${meta.id}_humann3.log

    rm -f ${meta.id}_combined.fastq
    """
}

process HUMANN3_RENORM {
    tag          "$meta.id"
    label        'small'
    publishDir   "${params.outdir}/functional/humann3/${meta.id}", mode: params.publish_dir_mode

    container 'biobakery/humann:3.9'

    input:
    tuple val(meta), path(genefamilies)
    tuple val(meta), path(pathabundance)

    output:
    tuple val(meta), path("${meta.id}_genefamilies_relab.tsv"),  emit: genefamilies_relab
    tuple val(meta), path("${meta.id}_pathabundance_relab.tsv"), emit: pathabundance_relab

    script:
    """
    humann_renorm_table \\
        --input ${genefamilies} \\
        --units relab \\
        --output ${meta.id}_genefamilies_relab.tsv

    humann_renorm_table \\
        --input ${pathabundance} \\
        --units relab \\
        --output ${meta.id}_pathabundance_relab.tsv
    """
}
