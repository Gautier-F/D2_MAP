#!/usr/bin/env nextflow

// génération d'un rapport html à partir du stats.txt sorti de bamSortIndex

process MultiQC {

    publishDir "results_${params.patient_id}/BamQC", mode: 'copy'
    container "${projectDir}/containers/multiqc_latest.sif"

    input:
        path stats_dir

    output:
        path "*.html",          optional: true
        path "multiqc_data",    optional: true

    script:


    """
    # création d'un fichier config pour multiqc (augmentation de la taille des fichiers analysés)
    cat <<EOF >> multiqc_config.yaml
    log_filesize_limit: 100000000     # 100MB
    module_max_filesize:
        samtools: 100000000           # 100MB spécifique samtools
    filesearch_lines_limit: 5000
    sp:
        samtools/stats:
            fn: "*.samtools.stats"
            contents: "# This file was produced by samtools stats"
            shared: true
    EOF


    multiqc . -n bam_QC.html 
    """
    }
