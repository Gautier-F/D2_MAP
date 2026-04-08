#!/usr/bin/env nextflow

/* 
alignement du .bam mergé lors de l'étape précédente avec dorado aligner
*/

process bamAlignment {
        tag "${meta.cond}"
        publishDir 'results/Bam_files', mode: 'symlink'
        container "${projectDir}/containers/dorado.sif"

        input:
            tuple val(meta), path(merged_bam)
            path path_to_ref_genome

        output:
            tuple val(meta), path("${meta.cond}_aligned.bam"),          emit: aligned_bam
            // path "${meta.cond}_depth_stats.txt",                        emit: depth_stats

        script:
        """
        # does file exist?
        if [ ! -s ${merged_bam} ]; then echo "Erreur: BAM d'entrée vide"; exit 1; fi
        dorado aligner --threads 8 ${path_to_ref_genome} ${merged_bam} > ${meta.cond}_aligned.bam

        # depth stats
        # samtools depth ${meta.cond}_aligned.bam | awk '{sum += \$3 } END \
        # { print "${meta.cond}_aligned.bam depth: " sum/NR }' | tee -a ${meta.cond}_depth_stats.txt
        """

}