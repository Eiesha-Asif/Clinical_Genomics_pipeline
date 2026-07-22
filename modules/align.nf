/*
 * modules/align.nf
 * ---------------------------------------------------------------------
 * Step: Align PacBio HiFi long reads to the reference genome.
 * Tool: minimap2, using the `-x map-hifi` preset built specifically for
 * PacBio HiFi (CCS) reads, then piped straight into a BAM with samtools.
 * Runs inside: containers/minimap2.sif
 * ---------------------------------------------------------------------
 */

process MINIMAP2_ALIGN {
    tag "$sample_reads.simpleName"
    publishDir "${params.outdir}/alignment", mode: 'copy', pattern: "*.bam"
    container params.sif_minimap2
    cpus 8
    memory '16 GB'

    input:
    path reference
    path sample_reads

    output:
    path "*.bam", emit: bam

    script:
    """
    minimap2 -ax map-hifi -t ${task.cpus} ${reference} ${sample_reads} \\
        | samtools view -bS - > ${params.sample}.aligned.bam
    """
}
