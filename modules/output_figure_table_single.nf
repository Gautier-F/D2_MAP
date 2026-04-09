#!/usr/bin/env nextflow

/* 
volcanoPlot sur les données dmrsinglebase (non enrichies: on récupère les cytosines de toutes les régions décrites 
comme étant différentiellement méthylées)
*/

process outputFigureTableSingle {

    publishDir "results_${params.patient_id}/VolcanoPlots", mode: 'copy', pattern: "*.png"
    publishDir "results_${params.patient_id}/DMR_tables", mode: 'copy', pattern: "*.xlsx"
    container "${projectDir}/containers/R_extended.sif"

    input:
        tuple val(meta_dmr), path(dmr_single_filtered_enriched)
        path path_to_script_volcano
        path path_to_script_source
        val type


    output:
        path "volcano_plot_${type}.png",             emit: volcano_plot
        path "barplot_feature_${type}.png",          emit: barplot_feature_type
        path "dmr_${type}_table.xlsx",               emit: dmr_table
        path "histo_dm_${type}_score.png",           emit: histo_score 
        path "CMplot_${type}_positive_score.png",    emit: cmplot_pos
        path "CMplot_${type}_negative_score.png",    emit: cmplot_neg

    script:
    def cond_a = meta_dmr.cond_a ?: "sans_nom_A"
    def cond_b = meta_dmr.cond_b ?: "sans_nom_B"

    """
    Rscript ${path_to_script_volcano} ${dmr_single_filtered_enriched} ${type} ${cond_a} ${cond_b}
    """

}