#!/usr/bin/env nextflow


process bamMergingFiltering {

        /* 
        Merge des .bam à la sortie du run Prométhion
        */
        tag "${meta.cond}" 
        publishDir 'results/Bam_files', mode: 'symlink', pattern: '*.bam'
        container "${projectDir}/containers/dorado_latest.sif" 

        input:
            tuple val(meta), path(input_path_bam_directory)

        output:
            tuple val(meta),  path("${meta.cond}_merged_filtered.bam"),      emit: bam_filtered
            path "${meta.cond}_depth_stats.txt",                       emit: depth_stats

        
        script:
        def cond = meta.cond

        """
        # merging
        samtools merge -o ${cond}_merged.bam ${input_path_bam_directory}/*.bam 
        # filtering ( Q >= 12 )
        samtools view -b -q 12 ${cond}_merged.bam > ${cond}_merged_filtered.bam

        # depth stats
        samtools depth ${cond}_merged.bam | awk '{sum += \$3 } END \
        { print "${cond}_merged.bam depth: " sum/NR }' | tee -a ${cond}_depth_stats.txt
        """
}
