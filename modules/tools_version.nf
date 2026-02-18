#!/usr/bin/env nextflow


process doradoSamtoolsVersion {

    container "${projectDir}/containers/dorado_latest.sif"

    output:
        path "dorado_samtools_version.txt", emit: dorado_samtools_version
    script:
    """ 
    dorado --version 2>&1 | awk '{print "dorado " \$0}' | tee -a dorado_samtools_version.txt
    samtools --version 2>&1 | head -n 2 | tee -a  dorado_samtools_version.txt
    """
    
}

process modkitBedtoolsVersion {
    
    container "${projectDir}/containers/modkit_v6_bedtools.sif"

    output:
        path "modkit_bedtools_version.txt", emit: modkit_bedtools_version

    script:
    """
    modkit --version | tee -a modkit_bedtools_version.txt
    bedtools --version 2>&1 | tee -a modkit_bedtools_version.txt
    """

}

process rVersion {
    container "${projectDir}/containers/R_extended.sif"

    output:
        path "R_version.txt", emit: r_version

    script:
    """
    R --version 2>&1 | head -n 1 | tee -a R_version.txt
    """
}