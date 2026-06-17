// Assembly sub-workflow: MEGAHIT (default) or metaSPAdes (--assembler metaspades)

include { MEGAHIT    } from '../modules/megahit'
include { METASPADES } from '../modules/metaspades'

workflow ASSEMBLY_WORKFLOW {
    take:
    ch_reads   // channel: [ val(meta), [ path(r1), path(r2) ] ]

    main:
    if (params.assembler == 'metaspades') {
        METASPADES(ch_reads)
        ch_contigs = METASPADES.out.contigs
    } else {
        MEGAHIT(ch_reads)
        ch_contigs = MEGAHIT.out.contigs
    }

    emit:
    contigs = ch_contigs
}
