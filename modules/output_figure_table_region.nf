#!/usr/bin/env nextflow

/* création du volcanoplot à partir de la table dmr_enriched (étape 6)  */

process outputFigureTableRegion {
    publishDir "results/VolcanoPlots", mode: 'copy', pattern: "*.png"
    publishDir "results/DMR_tables",   mode: 'copy', pattern: "*.xlsx"
    publishDir "results/CMplots",     mode: 'copy', pattern: "CMplot*.png"
    container "${projectDir}/containers/R_extended.sif"
    // stageInMode 'copy'

    input:
        tuple val(dmr_meta), path(dmr_filtered_enriched)
        path path_to_script_volcano
        path path_to_script_source
        val type


    output:
        path "volcano_plot_${type}.png",            emit: volcano_plot
        path "barplot_feature_region.png",          emit: barplot_feature_type
        path "dmr_${type}_table.xlsx",              emit: dmr_table
        path "histo_dm_region_score.png",           emit: histo_score 
        path "CMplot_region_positive_score.png",    emit: cmplot_pos
        path "CMplot_region_negative_score.png",    emit: cmplot_neg


    script:

    def cond_a = dmr_meta.cond_a
    def cond_b = dmr_meta.cond_b

    """
    
    /opt/conda/bin/Rscript  ${path_to_script_volcano} ${dmr_filtered_enriched} ${type} ${cond_a} ${cond_b}
    """
}