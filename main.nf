#!/usr/bin/env nextflow

/*
 * My Custom RNA-Seq / Variant Calling Pipeline
 * Inspired by nextflow-io/rnaseq-nf
 * Uses: minimap2 + samtools + Clair3
 *
 * ---------------------------------------------------------------------
 * NOTE FOR BEGINNERS (added in this fork, original logic untouched):
 * This is the "orchestrator" file of the pipeline. Nextflow reads this
 * file first. It does three things:
 *   1. Defines default parameter values (things you can override with --flag)
 *   2. Imports the individual pipeline steps ("modules") from ./modules/
 *   3. Wires the steps together in the `workflow { }` block below
 * You normally do NOT need to edit this file to run the pipeline.
 * ---------------------------------------------------------------------
 */

params.reads = null
params.reference = null
params.sample = "sample1"
params.outdir = "${launchDir}/results"

// Singularity containers
params.sif_minimap2 = "${projectDir}/containers/minimap2.sif"
params.sif_samtools = "${projectDir}/containers/minimap2.sif"
params.sif_clair3 = "${projectDir}/containers/clair3.sif"
params.model_path = "/opt/models/hifi"

// Import modules
include { SAMTOOLS_FAIDX } from './modules/index'
include { MINIMAP2_ALIGN } from './modules/align'
include { SAMTOOLS_SORT; SAMTOOLS_INDEX } from './modules/sort'
include { CLAIR3 } from './modules/variant'

workflow {

    main:
    log.info """\
    M Y - R N A S E Q - N F   P I P E L I N E
    ==========================================
    reference: ${params.reference}
    reads    : ${params.reads}
    sample   : ${params.sample}
    outdir   : ${params.outdir}
    """.stripIndent()

    // Validate inputs
    if (!params.reference) { error "Missing --reference parameter" }
    if (!params.reads) { error "Missing --reads parameter" }

    // Create channels
    ref_ch = Channel.fromPath(params.reference)
    reads_ch = Channel.fromPath(params.reads)

    // Run pipeline steps
    SAMTOOLS_FAIDX(ref_ch)
    MINIMAP2_ALIGN(ref_ch, reads_ch)
    SAMTOOLS_SORT(MINIMAP2_ALIGN.out.bam)
    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.sorted_bam)

    CLAIR3(
        SAMTOOLS_SORT.out.sorted_bam,
        SAMTOOLS_INDEX.out.bai,
        ref_ch,
        SAMTOOLS_FAIDX.out.fai
    )
}
