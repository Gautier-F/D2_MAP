#!/usr/bin/env nextflow

/* 
volcanoPlot sur les données dmrsinglebase (non enrichies: on récupère les cytosines de toutes les régions décrites 
comme étant différentiellement méthylées)
*/

process outputFigureTableSingle {

    publishDir 'results/VolcanoPlots', mode: 'copy', pattern: "*.png"
    publishDir 'results/DMR_tables', mode: 'copy', pattern: "*.xlsx"
    container "${projectDir}/containers/R_extended.sif"

    input:
        tuple val(meta_dmr), path(dmr_single_filtered_enriched)
        path path_to_script_volcano
        path path_to_script_source
        val type


    output:
        path "volcano_plot_${type}.png",    emit: volcano_plot
        path "dmr_${type}_table.xlsx",      emit: dmr_table
        // path "barplot_feature_${type}.png"

    script:
    def cond_a = meta_dmr.cond_a
    def cond_b = meta_dmr.cond_b

    """
    /opt/conda/bin/Rscript ${path_to_script_volcano} ${dmr_single_filtered_enriched} ${type} ${cond_a} ${cond_b}
    """

}