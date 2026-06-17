// Binning sub-workflow: MetaBAT2 → CheckM → (optional) GTDB-Tk

include { METABAT2 } from '../modules/metabat2'
include { CHECKM   } from '../modules/checkm'
include { GTDBTK   } from '../modules/gtdbtk'

workflow BINNING_WORKFLOW {
    take:
    ch_contigs   // channel: [ val(meta), path(contigs.fa.gz) ]
    ch_reads     // channel: [ val(meta), [ path(r1), path(r2) ] ]

    main:
    // Join reads and contigs on sample ID for depth-aware binning
    ch_binning_input = ch_contigs
        .join(ch_reads, by: 0)
        .map { meta, contigs, reads -> [meta, contigs, reads] }

    METABAT2(
        ch_binning_input.map { meta, contigs, _r -> [meta, contigs] },
        ch_binning_input.map { meta, _c, reads  -> [meta, reads] }
    )

    CHECKM(METABAT2.out.bins_dir)

    if (params.enable_gtdbtk) {
        ch_gtdbtk_db = Channel.value(file(params.gtdbtk_db))
        GTDBTK(METABAT2.out.bins_dir, ch_gtdbtk_db)
    }

    emit:
    bins       = METABAT2.out.bins
    checkm_tsv = CHECKM.out.tsv
}
