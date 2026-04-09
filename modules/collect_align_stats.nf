#!/usr/bin/env nextflow

// collect align stats produced at the bam_sort_index step (flagstat and stats)

process collectFlagstats{

    publishDir "results_${params.patient_id}/BamQC", mode: 'copy'

    input: 
        val flagstats
    
    output:
        path "Flagstats_dir", emit: flagstats_dir
    
    script:
    """
    mkdir -p Flagstats_dir
    cp ${flagstats.join(' ')} Flagstats_dir/

    """
}

process collectStats {
    publishDir "results_${params.patient_id}/BamQC", mode: 'copy'

    input:
    path stats  // Utilise 'path' pour les fichiers

    output:
    path "Stats_dir", emit: stats_dir

    script:
    """
    mkdir -p Stats_dir

    # Copie chaque fichier individuellement
    for f in ${stats}; do
        cp "\$f" Stats_dir/
    done

    # Vérification (optionnel)
    echo "Fichiers copiés dans Stats_dir :"
    ls -l Stats_dir/
    """
}