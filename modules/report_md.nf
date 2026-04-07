process mdReport {
    publishDir 'results/D2MAP_Report', mode: 'copy'
    container "${projectDir}/containers/R_extended.sif"

    input:
    val patient_id
    val cond_1
    val cond_2
    val date
    val analysis_type
    val mm_type
    val sid 
    path qc_stats
    path flagstats
    path tag_stats
    path histo_score_region
    path cmplot_pos_region
    path cmplot_neg_region
    path volcano_region
    path barplot_region
    path histo_score_single
    path cmplot_pos_single
    path cmplot_neg_single
    path volcano_single
    path barplot_single
    path table_region
    path table_single
    path targeted_genes_dir
    path version_id
    path report_res
    path rmd_file

    output:
    path "${date.replaceAll(' ', '_')}_report_${patient_id}.html"

    script:
    // On remplace les espaces par des underscores dans le nom de fichier pour éviter les bugs shell
    def safe_date = date.replaceAll(' ', '_')
    def report_name = "${safe_date}_report_${patient_id}.html"

    """
    Rscript -e "
        rmarkdown::render(
            input = '${rmd_file}',
            output_file = '${report_name}',
            params = list(
                patient_id = '${patient_id}',
                cond_1 = '${cond_1}',
                cond_2 = '${cond_2}',
                date = '${date}',
                sid = '${sid}',
                analysis_type = '${analysis_type}',
                mm_type = '${mm_type}',
                qc_stats = '${qc_stats}',
                bam1_stats = '${flagstats[0]}',
                bam2_stats = '${flagstats[1]}',
                mm_tag_stats = '${tag_stats}',
                histo_score_region = '${histo_score_region}',
                cmplot_pos_region = '${cmplot_pos_region}',
                cmplot_neg_region = '${cmplot_neg_region}',
                volcanoplot_region = '${volcano_region}',
                barplot_region = '${barplot_region}',
                histo_score_single = '${histo_score_single}',
                cmplot_pos_single = '${cmplot_pos_single}',
                cmplot_neg_single = '${cmplot_neg_single}',
                volcanoplot_single = '${volcano_single}',
                barplot_single = '${barplot_single}',
                table_region = '${table_region}',
                table_single = '${table_single}',
                targeted_genes = '${targeted_genes_dir}',
                version_id = '${version_id}'
            )
        )
    "
    """
    
}