#!/usr/bin/env nextflow

/*
tri et indexation du .bam aligné
*/

process bamSortIndex {
    tag "${meta.cond}"
    publishDir "results_${params.patient_id}/Bam_files", mode: 'symlink', pattern: '*.{bam,bai}'
    publishDir "results_${params.patient_id}/qc_stats", mode: 'copy', pattern: '*.{txt,tsv}'
    container "${projectDir}/containers/dorado.sif"

    input:
        tuple val(meta), path(aligned_bam)
        

    output:
        tuple val(meta), path("${meta.cond}_sort.bam"),  path("${meta.cond}_sort.bam.bai"),     emit: tuple_bam_bai
        path "${meta.cond}_flagstat.txt",                                                       emit: flagstats
        path "${meta.cond}_summary_qc.tsv",                                                     emit: qc_stats
        

    script:
    def cond = meta.cond

    """
    samtools sort ${aligned_bam} > ${cond}_sort.bam
    samtools index ${cond}_sort.bam

    ### stats

    samtools flagstat ${aligned_bam} > ${cond}_flagstat.txt

    samtools stats ${cond}_sort.bam 2>/dev/null > ${cond}_raw_stats.txt

        # Extraction des métriques pertinentes pour du non-aligné
        READS_COUNT=\$(grep "^SN" ${cond}_raw_stats.txt | grep "sequences:" | cut -f 3)
        TOTAL_BASES=\$(grep "^SN" ${cond}_raw_stats.txt | grep "total length:" | cut -f 3)
        PHRED=\$(grep "^SN" ${cond}_raw_stats.txt | grep "average quality:" | cut -f 3)
        AVG_LEN=\$(grep "^SN" ${cond}_raw_stats.txt | grep "average length:" | cut -f 3)

        # N50
        # On récupère la 10ème colonne (séquence) et on compte sa longueur
        samtools view ${cond}_sort.bam | awk '{print length(\$10)}' | sort -rn > lengths.txt
        N50=\$(awk '{
            len[i++] = \$1;
            sum += \$1;
        }
        END {
            for (j = 0; j < i; j++) {
                current_sum += len[j];
                if (current_sum >= sum / 2) {
                    print len[j];
                    exit;
                }
            }
        }' lengths.txt)

        MEAN_DEPTH=\$(samtools depth ${cond}_sort.bam | awk '{sum += \$3 } END \
        {if (NR > 0) print sum/NR; else print 0}')

        MAPQ_MEAN=\$(samtools view ${cond}_sort.bam | awk '{sum += \$5; count++} END {if (count > 0) print sum/count; else print 0}')

        # Création d'un fichier de synthèse 
        echo -e "Sample\\tReads\\tTotal_Bases\\ttN50\\tPhred\\tDEPTH_Mean\\tMAPQ_Mean" > ${cond}_summary_qc.tsv
        echo -e "${cond}\\t\$READS_COUNT\\t\$TOTAL_BASES\\t\$N50\\t\$PHRED\\t\$MEAN_DEPTH\\t\$MAPQ_MEAN" >> ${cond}_summary_qc.tsv

    """
}