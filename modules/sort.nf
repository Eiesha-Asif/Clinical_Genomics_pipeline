/*
 * modules/sort.nf
 * ---------------------------------------------------------------------
 * Step 1: Sort the aligned BAM by genomic coordinate (`samtools sort`).
 *         Almost every downstream tool (variant callers, viewers like
 *         IGV) requires a coordinate-sorted, indexed BAM.
 * Step 2: Index the sorted BAM (`samtools index`) so tools can jump
 *         to any region without reading the whole file.
 * Runs inside: containers/minimap2.sif
 * ---------------------------------------------------------------------
 */

process SAMTOOLS_SORT {
    tag "$bam.simpleName"
    publishDir "${params.outdir}/alignment", mode: 'copy'
    container params.sif_samtools
    cpus 2
    memory '4 GB'

    input:
    path bam

    output:
    path "${params.sample}.sorted.bam", emit: sorted_bam

    script:
    """
    samtools sort -@ ${task.cpus} -o ${params.sample}.sorted.bam ${bam}
    """
}

process SAMTOOLS_INDEX {
    tag "$sorted_bam.simpleName"
    publishDir "${params.outdir}/alignment", mode: 'copy'
    container params.sif_samtools
    cpus 2
    memory '4 GB'

    input:
    path sorted_bam

    output:
    path "${sorted_bam}.bai", emit: bai

    script:
    """
    samtools index ${sorted_bam}
    """
}
