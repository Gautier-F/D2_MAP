#!/usr/bin/env nextflow

/*
methylation différentielle par région (windowing de 1Kb / step 0.5Kb)
*/

process modkitDmrPair {
    cpus 20
    memory '40 GB'


    publishDir 'results/Bed_files', mode: 'symlink', pattern: '*.bed'
    publishDir 'results/Tag_stats', mode: 'copy', pattern: '*.txt'

    container "${projectDir}/containers/modkit_v6_bedtools.sif"

    input:
        path pileup_files
        val meta
        path path_to_ref_genome
        path path_to_region
        path bam_files
        val modified_base

    output:
        tuple val(dmr_meta), path("${output_name}"),    emit: tuple_dmr_region
        path "tag_stats.txt",                           emit: tag_stats

    script:
    def base = modified_base in ["5mC", "5hmC"] ? "C" : "A"

    def bed_a = pileup_files[0]
    def bed_b = pileup_files[1]

    def meta_a = meta[0]
    def meta_b = meta[1]

    // meta DMR
    dmr_meta = [
        id: meta_a.id,
        cond_a: meta_a.cond,
        cond_b: meta_b.cond,
        analysis: "DMR_region"
    ]

    output_name = "dmr_cond_a_${meta_a.cond}_vs_cond_b_${meta_b.cond}.bed"
    
    // récupération des .bam d'origine pour modbam check-tags
    def bam_a = bam_files[0]
    def bam_b = bam_files[1]

    """
    ########  MM tags stats:  ###########
    echo "<strong>${meta_a.cond}:</strong>" > tag_stats.txt
    modkit modbam check-tags ${bam_a} --head 100 2>&1 | head -n 3 >> tag_stats.txt
    echo -e "\n============================\n" >> tag_stats.txt

    echo "<strong>${meta_b.cond}:</strong>" >> tag_stats.txt
    modkit modbam check-tags ${bam_b} --head 100 2>&1 | head -n 3 >> tag_stats.txt
    echo -e "\n============================\n" >> tag_stats.txt

    ######## DMR ##############

    bgzip -k ${bed_a.name}
    bgzip -k ${bed_b.name}

    tabix -p bed ${bed_a.name}.gz
    tabix -p bed ${bed_b.name}.gz

    modkit dmr pair \
        -a ${bed_a.name}.gz \
        -b ${bed_b.name}.gz \
        -o ${output_name} \
        -r ${path_to_region} \
        --ref ${path_to_ref_genome} \
        --base ${base} \
        --min-coverage 3 \
        --threads ${task.cpus} \
        --fine-grained
    """
}