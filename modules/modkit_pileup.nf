#!/usr/bin/env nextflow

/*
pileup "traditionnal" des .bam alignés, triés et indexés (position CG, prise en compte de C et 5mC uniquement)
*/

process modkitPileup {

    publishDir 'results/Bed_files', mode: "symlink"
    container "${projectDir}/containers/modkit_v6_bedtools.sif"

    input:
        tuple val(meta), path(input_bam), path(input_bam_index)
        path path_to_ref_genome
        val modified_bases

    output:
        tuple val(meta), path("${meta.cond}_pileup_depth_filtered.bed"),   emit: bam_pileup
    
    script:
    def prefix = "${meta.cond}"
    """
    modkit pileup \
        ${input_bam} \
        ${prefix}_pileup.bed.gz \
        --ref ${path_to_ref_genome} \
        --cpg \
        --modified-bases ${modified_bases} \
        --combine-mods \
        --threads 16 \
        --bgzf

    # depth >=3
    zcat ${prefix}_pileup.bed.gz | awk '\$5 >= 3' > ${prefix}_pileup_depth_filtered.bed

    """
}