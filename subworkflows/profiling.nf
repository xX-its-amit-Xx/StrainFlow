// Profiling sub-workflow: Kraken2 + Bracken + MetaPhlAn4 + StrainPhlAn + inStrain

include { KRAKEN2                    } from '../modules/kraken2'
include { BRACKEN                    } from '../modules/bracken'
include { METAPHLAN4                 } from '../modules/metaphlan4'
include { STRAINPHLAN_SAMPLE2MARKERS } from '../modules/strainphlan'
include { STRAINPHLAN_EXTRACT_MARKERS} from '../modules/strainphlan'
include { STRAINPHLAN                } from '../modules/strainphlan'
include { INSTRAIN_PROFILE           } from '../modules/instrain'
include { INSTRAIN_COMPARE           } from '../modules/instrain'

workflow PROFILING_WORKFLOW {
    take:
    ch_reads   // channel: [ val(meta), [ path(r1), path(r2) ] ]

    main:
    ch_kraken2_db  = Channel.value(file(params.kraken2_db))
    ch_metaphlan_db = Channel.value(file(params.metaphlan_db))
    ch_instrain_db  = Channel.value(file(params.instrain_db))

    // ── Kraken2 + Bracken ────────────────────────────────────────────────────
    KRAKEN2(ch_reads, ch_kraken2_db)
    BRACKEN(KRAKEN2.out.report, ch_kraken2_db)

    // ── MetaPhlAn4 ───────────────────────────────────────────────────────────
    METAPHLAN4(ch_reads, ch_metaphlan_db)

    // ── StrainPhlAn ──────────────────────────────────────────────────────────
    // Extract per-sample consensus markers
    STRAINPHLAN_SAMPLE2MARKERS(METAPHLAN4.out.sam, ch_metaphlan_db)

    // Detect clades from all samples, extract reference markers per clade
    ch_clades = METAPHLAN4.out.profile
        .map { _meta, profile ->
            profile.text.readLines()
                .findAll { it =~ /\|s__[^|]+$/ }   // species-level lines only
                .collect { it.split('\t')[0].split('\\|').last() }
        }
        .flatten()
        .unique()

    STRAINPHLAN_EXTRACT_MARKERS(ch_clades, ch_metaphlan_db)

    ch_all_markers = STRAINPHLAN_SAMPLE2MARKERS.out.markers.map { _m, pkl -> pkl }.collect()
    STRAINPHLAN(
        ch_clades,
        ch_all_markers,
        STRAINPHLAN_EXTRACT_MARKERS.out.fna.map { _c, fna -> fna },
        ch_metaphlan_db
    )

    // ── inStrain ─────────────────────────────────────────────────────────────
    INSTRAIN_PROFILE(ch_reads, ch_instrain_db)

    ch_all_profiles = INSTRAIN_PROFILE.out.profile_dir.map { _m, d -> d }.collect()
    INSTRAIN_COMPARE(ch_all_profiles, ch_instrain_db)

    emit:
    kraken2_report   = KRAKEN2.out.report
    bracken_report   = BRACKEN.out.report
    metaphlan_profile = METAPHLAN4.out.profile
    strain_profiles  = STRAINPHLAN.out.tsv.mix(INSTRAIN_COMPARE.out.tsv)
}
