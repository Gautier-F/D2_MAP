#!/usr/bin/env nextflow

/* 
alignement du .bam mergé lors de l'étape précédente avec dorado aligner
*/

process bamAlignment {
        tag "${meta.cond}"
        publishDir 'results/Bam_files', mode: 'symlink'
        container "${projectDir}/containers/dorado_latest.sif"

        input:
            tuple val(meta), path(merged_bam)
            path path_to_ref_genome

        output:
            tuple val(meta), path("${meta.cond}_aligned.bam"), emit: aligned_bam

        script:
        """
        dorado aligner --threads 8 ${path_to_ref_genome} ${merged_bam} > ${meta.cond}_aligned.bam
        """

}