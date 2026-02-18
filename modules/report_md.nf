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
    path depth_stats
    path flagstats
    path tag_stats
    path histo_score
    path cmplot_pos
    path cmplot_neg
    path volcano_region
    path barplot_region
    path volcano_single
    path table_region
    path table_single
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
    /opt/conda/bin/Rscript -e "
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
                depth_stats = '${depth_stats}',
                bam1_stats = '${flagstats[0]}',
                bam2_stats = '${flagstats[1]}',
                mm_tag_stats = '${tag_stats}',
                histo_score = '${histo_score}',
                cmplot_pos = '${cmplot_pos}',
                cmplot_neg = '${cmplot_neg}',
                volcanoplot_region = '${volcano_region}',
                barplot_region = '${barplot_region}',
                volcanoplot_single = '${volcano_single}',
                table_region = '${table_region}',
                table_single = '${table_single}',
                version_id = '${version_id}'
            )
        )
    "
    """
    
}