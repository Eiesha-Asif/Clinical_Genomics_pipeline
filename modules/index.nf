/*
 * modules/index.nf
 * ---------------------------------------------------------------------
 * Step: Index the reference genome with `samtools faidx`.
 * Why: Clair3 and samtools both need a `.fai` index file next to the
 * reference FASTA before they can jump to arbitrary positions in it.
 * Runs inside: containers/minimap2.sif (has samtools installed)
 * ---------------------------------------------------------------------
 */

process SAMTOOLS_FAIDX {
    tag "$reference.simpleName"
    publishDir "${params.outdir}/reference", mode: 'copy'
    container params.sif_samtools

    input:
    path reference

    output:
    path "${reference}.fai", emit: fai

    script:
    """
    samtools faidx ${reference}
    """
}
