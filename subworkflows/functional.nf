// Functional sub-workflow: HUMAnN3 (pathway + gene-family abundances)

include { HUMANN3        } from '../modules/humann3'
include { HUMANN3_RENORM } from '../modules/humann3'

workflow FUNCTIONAL_WORKFLOW {
    take:
    ch_reads   // channel: [ val(meta), [ path(r1), path(r2) ] ]

    main:
    ch_nt_db   = Channel.value(file(params.humann3_nt_db))
    ch_prot_db = Channel.value(file(params.humann3_prot_db))

    HUMANN3(ch_reads, ch_nt_db, ch_prot_db)
    HUMANN3_RENORM(HUMANN3.out.genefamilies, HUMANN3.out.pathabundance)

    emit:
    genefamilies    = HUMANN3_RENORM.out.genefamilies_relab
    pathabundance   = HUMANN3_RENORM.out.pathabundance_relab
    pathcoverage    = HUMANN3.out.pathcoverage
}
