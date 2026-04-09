#!/bin/usr/env nextflow

// data table for regulatory features

process regulatoryFeaturesTables {

    publishDir "results_${params.patient_id}", mode: 'copy'
    container "${projectDir}/containers/R_extended.sif"

    input:
        tuple val(dmr_meta_region), path(dmr_filtered_enriched_region)
        tuple val(dmr_meta_single), path(dmr_filtered_enriched_single)
        path path_to_script_wrapper
        path path_to_script_nearest_genes
        path path_to_gene_annotation_gtf
        path path_to_df_volcano_region
        path path_to_df_volcano_single


    output:
        path "Targeted_genes", emit: targeted_genes_dir


    script:
    """
    mkdir -p Targeted_genes/{Region,Single}
    Rscript  --vanilla  ${path_to_script_wrapper} \
                        ${dmr_filtered_enriched_region} \
                        ${dmr_filtered_enriched_single} \
                        ${path_to_gene_annotation_gtf} \
                        ${path_to_df_volcano_region} \
                        ${path_to_df_volcano_single} 
                        
    shopt -s extglob
    mv !(dmr_region_table|dmr_single_table).xlsx Targeted_genes/Region/ 2>/dev/null || true
    """
}