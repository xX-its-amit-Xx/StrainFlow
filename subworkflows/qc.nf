// QC sub-workflow: pre-QC FastQC → fastp trimming → post-QC FastQC → host removal

include { FASTQC               } from '../modules/fastqc'
include { FASTP                } from '../modules/fastp'
include { BOWTIE2_HOST_REMOVAL } from '../modules/bowtie2_host_removal'

workflow QC_WORKFLOW {
    take:
    ch_reads   // channel: [ val(meta), [ path(r1), path(r2) ] ]

    main:
    // Pre-trimming QC
    FASTQC(ch_reads)

    // Adapter / quality trimming
    FASTP(ch_reads)

    // Post-trimming QC
    FASTQC_POST = FASTQC(FASTP.out.reads)   // separate tag via ext.prefix

    // Host read removal
    ch_host_index = Channel.value(file(params.host_index))
    BOWTIE2_HOST_REMOVAL(FASTP.out.reads, ch_host_index)

    emit:
    clean_reads  = BOWTIE2_HOST_REMOVAL.out.reads
    fastqc_zip   = FASTQC.out.zip.mix(FASTQC_POST.out.zip)
    fastp_json   = FASTP.out.json
}
