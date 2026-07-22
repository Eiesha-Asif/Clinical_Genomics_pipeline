/*
 * modules/variant.nf
 * ---------------------------------------------------------------------
 * Step: Call SNPs and small Indels from the sorted, indexed BAM using
 * Clair3 — a deep-learning variant caller built for long-read data
 * (PacBio HiFi / Oxford Nanopore).
 *
 * Clair3 needs:
 *   --bam_fn        sorted + indexed BAM
 *   --ref_fn        reference FASTA + .fai next to it
 *   --model_path    a pre-trained neural network model matching your
 *                    sequencing platform (HiFi model here)
 *   --platform       hifi | ont | ilmn
 * Runs inside: containers/clair3.sif
 * ---------------------------------------------------------------------
 */

process CLAIR3 {
    tag "$sample_id"
    publishDir "${params.outdir}/variants", mode: 'copy'
    container params.sif_clair3
    cpus 4
    memory '8 GB'

    input:
    path sorted_bam
    path bai
    path reference
    path fai

    output:
    path "clair3_output/merge_output.vcf.gz", emit: vcf

    script:
    sample_id = params.sample
    """
    mkdir -p clair3_output
    run_clair3.sh \\
        --bam_fn=${sorted_bam} \\
        --ref_fn=${reference} \\
        --threads=${task.cpus} \\
        --platform="hifi" \\
        --model_path=${params.model_path} \\
        --output=clair3_output \\
        --sample_name=${sample_id} \\
        --include_all_ctgs
    """
}
