#!/usr/bin/env nextflow

/*
tri et indexation du .bam aligné
*/

process bamSortIndex {
    tag "${meta.cond}"
    publishDir 'results/Bam_files', mode: 'symlink', pattern: '*.{bam,bai}'
    container "${projectDir}/containers/dorado_latest.sif"

    input:
        tuple val(meta), path(aligned_bam)
        

    output:
        tuple val(meta), path("${meta.cond}_sort.bam"),  path("${meta.cond}_sort.bam.bai"),     emit: tuple_bam_bai
        path "${meta.cond}.flagstat.txt",                                                       emit: flagstats
        path "${meta.cond}.samtools.stats",                                                     emit: stats

    script:
    def cond = meta.cond

    """
    samtools sort ${aligned_bam} > ${cond}_sort.bam
    samtools index ${cond}_sort.bam

    ### stats
    samtools flagstat ${aligned_bam} > ${cond}.flagstat.txt
    samtools stats ${cond}_sort.bam 2>/dev/null > ${cond}.samtools.stats

    """
}
