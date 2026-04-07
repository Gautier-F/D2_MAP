#!/usr/bin/env nextflow

include { bamMergingFiltering }                     from './modules/bam_merging_filtering.nf'
include { bamAlignment }                            from './modules/bam_alignment.nf'
include { bamSortIndex }                            from './modules/bam_sort_index.nf'
include { collectFlagstats }                        from './modules/collect_align_stats.nf'
include { collectStats }                            from './modules/collect_align_stats.nf'
include { MultiQC }                                 from './modules/multiqc.nf'
include { modkitPileup }                            from './modules/modkit_pileup.nf'
include { modkitDmrPair }                           from './modules/modkit_dmr_windows.nf'
include { dmrFilteringEnrichment }                  from './modules/modkit_dmr_filtering_enrichment.nf'
include { outputFigureTableRegion }                 from './modules/output_figure_table_region.nf'
include { modkitDmrPairSingleBase }                 from './modules/modkit_dmr_2_single_base.nf'
include { dmrSinglebaseFilteringEnrichment }        from './modules/modkit_dmr_singlebase_filtering_enrichment.nf'
include { outputFigureTableSingle }                 from './modules/output_figure_table_single.nf'
include { regulatoryFeaturesTables }                from './modules/output_regulatory_feature_tables.nf'
include { doradoSamtoolsVersion }                   from './modules/tools_version.nf'
include { modkitBedtoolsVersion }                   from './modules/tools_version.nf'
include { rVersion }                                from './modules/tools_version.nf'
include { mdReport }                                from './modules/report_md.nf'

// récupération de la date (utilisée dans le rapport)
def date = new Date()
def dateAnalyse =   date.format("yyyy-MM-dd")
def heureAnalyse =  date.format("HH") + ":" +
                    date.format("mm") + ":" +
                    date.format("ss")
def dateHeure = "${dateAnalyse} ${heureAnalyse}"
def session_id = workflow.sessionId
println(dateHeure)

// vérification des paramètres chargés à partir du fichier json:
log.info """
    D2_MAP PIPELINE - Loaded Params
    ====================================

    Patient_ID              : ${params.patient_id}
    Analyse                 : ${params.analysis}
    Modified base           : ${params.modified_bases}
    Bam 1                   : ${params.path_to_bam_1}
    Label cond. 1           : ${params.cond_1}
    Bam 2                   : ${params.path_to_bam_2}
    Label cond. 2           : ${params.cond_2}
    Reference gen.          : ${params.path_to_ref}
    Reg. Feat. annot.       : ${params.path_to_regulatory_features_gtf}
    Genes annot.            : ${params.path_to_gene_annotation_gtf}
    Windows                 : ${params.path_to_region}
    Seuil Score DMR         : ${params.dmr_score_thr}

    =====================================
"""

// params report

params.report_ressources = [
                    "${projectDir}/MD_report/styles_v7.css",
                    "${projectDir}/MD_report/Logo_D2MAP.gif"
                    ]
params.date = dateHeure
params.sid = session_id
//--------------------------------------------------------------------------------------------
//params internes
params.path_to_script_volcano = "${projectDir}/R_scripts/script_volcano.R"
params.path_to_script_wrapper= "${projectDir}/R_scripts/wrapper_nearest_genes.R"
params.path_to_script_source = "${projectDir}/R_scripts/R_functions_D2_MAP.R"
params.path_to_script_nearest_genes = "${projectDir}/R_scripts/nearest_genes_functions.R"


// affichage du logo D2_MAP:
println "\u001b[1;30;104m \udb83\ude95              D2_MAP \u001b[0m\u001b[3;30;104mv1.0.0\u001b[23m\u001b[30;104m            \udb83\ude95  \u001b[0m"

workflow {

    // canal tuple [meta/path_to_bam]
    ch_bam_1 = Channel
                    .fromPath("${params.path_to_bam_1}")
                    .map { it -> [ [id: params.patient_id, cond: params.cond_1], it ]}
    ch_bam_2 = Channel
                    .fromPath("${params.path_to_bam_2}")
                    .map { it -> [ [id: params.patient_id, cond: params.cond_2], it ]}
    //channel
    merge_ch = ch_bam_1.concat(ch_bam_2)
    
    bamMergingFiltering(merge_ch)

    bamAlignment(bamMergingFiltering.out.bam_merged, params.path_to_ref)

    bamSortIndex(bamAlignment.out.aligned_bam)

    modkitPileup(bamSortIndex.out.tuple_bam_bai, params.path_to_ref, params.modified_bases)

    //collecte des 2 fichiers bed dans un channel unique et sécurisation de l'ordre des fichiers bed ET bam (cond_1 puis cond_2)
    ch_ordered_pileup_files = modkitPileup.out.bam_pileup
                            .toSortedList( { a, b -> a[0].cond <=> b[0].cond } )
                            .map { list -> list.collect { it[1]} } // uniquement les .baseDir
    
    ch_ordered_pileup_meta = modkitPileup.out.bam_pileup
                            .toSortedList( { a, b -> a[0].cond <=> b[0].cond } )
                            .map { list -> list.collect { it[0]} }
    
    // collecte des 2 fichiers bam d'origine pour modbam check-tags
    ch_ordered_bam = bamSortIndex.out.tuple_bam_bai
                            .toSortedList( { a, b -> a[0].cond <=> b[0].cond } ) // Trie par condition
                            .map { list -> [ list[0][1], list[1][1]] }
    
    modkitDmrPair(ch_ordered_pileup_files, 
                    ch_ordered_pileup_meta,
                    params.path_to_ref,
                    params.path_to_region,
                    ch_ordered_bam,
                    params.modified_bases )

    dmrFilteringEnrichment(modkitDmrPair.output.tuple_dmr_region, 
                            params.path_to_regulatory_features_gtf, 
                            params.dmr_score_thr)

    outputFigureTableRegion(dmrFilteringEnrichment.output.dmr_filtered_enriched, 
                            params.path_to_script_volcano, 
                            params.path_to_script_source, 
                            "region" )

    modkitDmrPairSingleBase(ch_ordered_pileup_files, 
                            ch_ordered_pileup_meta, 
                            dmrFilteringEnrichment.output.dmr_filtered, 
                            params.path_to_ref, 
                            params.modified_bases)

    dmrSinglebaseFilteringEnrichment(modkitDmrPairSingleBase.output.tuple_dmr_single, 
                                    params.path_to_regulatory_features_gtf, 
                                    params.dmr_score_thr)

    outputFigureTableSingle(dmrSinglebaseFilteringEnrichment.output.tuple_dmr_filtered_enriched_single, 
                            params.path_to_script_volcano, 
                            params.path_to_script_source, 
                            "single")
    
    regulatoryFeaturesTables(dmrFilteringEnrichment.output.dmr_filtered_enriched, 
                            dmrSinglebaseFilteringEnrichment.output.tuple_dmr_filtered_enriched_single, 
                            params.path_to_script_wrapper,
                            params.path_to_script_nearest_genes,
                            params.path_to_gene_annotation_gtf,
                            outputFigureTableRegion.output.dmr_table,
                            outputFigureTableSingle.output.dmr_table,
                            )

    // Collecte des versions des différents outils
    doradoSamtoolsVersion()
    modkitBedtoolsVersion()
    rVersion()
    // version nextflow
    all_versions_file_ch = Channel.of("Nextflow version: ${workflow.nextflow.version.toString()}")
        .concat(
            doradoSamtoolsVersion.out.dorado_samtools_version,
            modkitBedtoolsVersion.out.modkit_bedtools_version,
            rVersion.out.r_version
        )
        .collectFile(
            name: 'all_versions.txt',
            storeDir: 'results/Versions',
            newLine: true
        )



    report_res = Channel
                    .fromPath(params.report_ressources)
                    .collect() 
    mdReport(
            params.patient_id, 
            params.cond_1, 
            params.cond_2,
            params.date,
            params.analysis,
            params.modified_bases,
            params.sid,
            bamSortIndex.out.qc_stats.collectFile(name: 'bam_stats.txt', storeDir: 'results/qc_stats', newLine: true),
            bamSortIndex.out.flagstats.collect(),
            modkitDmrPair.out.tag_stats,
            outputFigureTableRegion.out.histo_score,
            outputFigureTableRegion.out.cmplot_pos,
            outputFigureTableRegion.out.cmplot_neg,
            outputFigureTableRegion.out.volcano_plot,
            outputFigureTableRegion.out.barplot_feature_type,
            outputFigureTableSingle.out.histo_score,
            outputFigureTableSingle.out.cmplot_pos,
            outputFigureTableSingle.out.cmplot_neg,
            outputFigureTableSingle.out.volcano_plot,
            outputFigureTableSingle.out.barplot_feature_type,
            outputFigureTableRegion.out.dmr_table,
            outputFigureTableSingle.out.dmr_table,
            regulatoryFeaturesTables.out.targeted_genes_dir,
            all_versions_file_ch,
            report_res,
            file("${projectDir}/MD_report/md_report_v3.rmd")
            )

}
