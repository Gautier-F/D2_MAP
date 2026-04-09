#!/usr/bin/env nextflow 

/* filtrage de l'output dmr sur le score de robustesse */

process dmrFilteringEnrichment {

    publishDir "results_${params.patient_id}/Bed_files", mode: 'symlink'
    container  "${projectDir}/containers/modkit_v6_bedtools.sif"

    input:
        tuple val(dmr_meta), path(dmr_bed)
        path path_to_annotation_bed
        val score_dmr

    output:
        tuple val(dmr_meta), path("${dmr_bed.baseName}_filtered_enriched.bed"),     emit: dmr_filtered_enriched
        tuple val(dmr_meta), path("${dmr_bed.baseName}_filtered.bed"),              emit: dmr_filtered

    script:

    """
    # Filtrage sur score DMR
    awk -v dmr_score="${score_dmr}"  '\$5 > dmr_score' ${dmr_bed} \
    > ${dmr_bed.baseName}_filtered.bed

    bedtools intersect -a ${dmr_bed}  \
    -b <(awk '{ if(\$0 !~ /^#/ && \$0 !~ /^chr/) print "chr"\$0; else print \$0 }' ${path_to_annotation_bed}) \
    -wa -wb | sort -u > ${dmr_bed.baseName}_filtered_enriched.bed
    """

}