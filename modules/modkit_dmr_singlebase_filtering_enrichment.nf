#!/usr/bin/env nextflow 

/* filtrage de l'output dmr sur le score de robustesse */

process dmrSinglebaseFilteringEnrichment {

    publishDir 'results/Bed_files', mode: 'symlink'
    container  "${projectDir}/containers/modkit_v6_bedtools.sif"

    input:
        tuple val(meta_dmr), path(dmr_single)
        path path_to_annotation_bed
        val score_dmr

    output:
        tuple val(meta_dmr), path("${dmr_single.baseName}_filtered_enriched.bed"), emit: tuple_dmr_filtered_enriched_single
        tuple val(meta_dmr), path("${dmr_single.baseName}_filtered.bed"), emit: tuple_dmr_filtered

    script:


    """
    # Filtrage sur score DMR
    awk '\$5 >= ${score_dmr}' ${dmr_single} > ${dmr_single.baseName}_filtered.bed

    bedtools intersect -a ${dmr_single.baseName}_filtered.bed  \
    -b <(awk '{ if(\$0 !~ /^#/ && \$0 !~ /^chr/) print "chr"\$0; else print \$0 }' ${path_to_annotation_bed}) \
    -wa -wb | sort -u > ${dmr_single.baseName}_filtered_enriched.bed
    """

}