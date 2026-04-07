#!/usr/bin/env nextflow


process bamMergingFiltering {

        /* 
        Merge des .bam à la sortie du run Prométhion
        */
        tag "${meta.cond}" 
        publishDir 'results/Bam_files', mode: 'symlink', pattern: '*.bam'
        publishDir  'results/qc_stats', mode: 'copy', pattern: '*.{txt, tsv}'
        container "${projectDir}/containers/dorado_latest.sif" 

        input:
            tuple val(meta), path(input_path_bam_directory)

        output:
            tuple val(meta),  path("${meta.cond}_merged.bam"),      emit: bam_merged

        
        script:
        def cond = meta.cond

        """
        # merging
        samtools merge -o ${cond}_merged.bam ${input_path_bam_directory}/*.bam 
        # filtering ( Q >= 12 )
        # samtools view -h -b -e '[qs] >= 12' ${cond}_merged.bam > ${cond}_merged_filtered.bam
        """
}

