#!/usr/bin/env nextflow

/* DM des cytosines présentes dans les régions différentiellement méthylées identifiées à l'étape 5 (dmr filtré sur le score mais 
non enrichie: toutes les cytosines de ces régions seront analysées indépendemment de la nature des régions où elles sont localisées. 
Analyse avec modkit dmr pair single position. A noter que la tendance globale de méthylation observée par région 
ne se reflète pas forcément au niveau des cytosines prises une à une */

process modkitDmrPairSingleBase {

    publishDir 'results/Bed_files', mode: 'symlink'
    container "${projectDir}/containers/modkit_v6_bedtools.sif"

    input:
        path pileup_files
        val meta_pileup
        val  tuple_dmr_filtered // output étape 6
        path path_to_ref_genome
        val modified_base

    output:
        tuple val(meta_dmr),  path("${output_name}"), emit: tuple_dmr_single

    script:
    def base = modified_base in ["5mC", "5hmC"] ? "C" : "A"

    def pileup_a = pileup_files[0]
    def pileup_b = pileup_files[1]
    
    def meta_a = meta_pileup[0]
    def meta_b = meta_pileup[1]
    
    def dmr_filtered = tuple_dmr_filtered[1]

    meta_dmr = [
            id: meta_a.id,
            cond_a: meta_a.cond,
            cond_b: meta_b.cond,
            analysis: "DMR_single"
            ]

    output_name = "dmr_singlebase_${meta_a.cond}_vs_${meta_b.cond}.bed"

    """
    # récupération des positions des regions d'intérêt
    sort -u ${dmr_filtered} | cut -f1-3 > region_of_interest.bed # les régions ayant un score dmr > seuil indiqué dans les inputs sont conservées

    # restriction des pileups à ces régions

    bedtools intersect -a ${pileup_a} -b region_of_interest.bed | bgzip > ${meta_a.cond}_pileup_restricted.gz
    tabix -p bed ${meta_a.cond}_pileup_restricted.gz

    bedtools intersect -a ${pileup_b} -b region_of_interest.bed | bgzip > ${meta_b.cond}_pileup_restricted.gz
    tabix -p bed ${meta_b.cond}_pileup_restricted.gz  

    # DM singlebase
    modkit dmr pair \
    -a ${meta_a.cond}_pileup_restricted.gz \
    -b ${meta_b.cond}_pileup_restricted.gz \
    -o ${output_name}\
    --ref ${path_to_ref_genome} \
    --base ${base} \
    --threads 16

    """

}