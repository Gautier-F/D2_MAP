#!/bin/bash

# This script builds the Apptainer images for D2_MAP. It should be run from the root of the D2_MAP repository.
path_to_genome_folder="$1"
WINDOW=${2:-1000}
STEP=${3:-500}

path_to_d2_map_root=$(pwd)

export APPTAINER_CACHEDIR=$path_to_d2_map_root/.apptainer_cache
export TMPDIR=$path_to_d2_map_root/tmp
mkdir -p $APPTAINER_CACHEDIR $TMPDIR 
mkdir -p $APPTAINER_CACHEDIR/containers

# Build the Apptainer images
module load apptainer

if [ ! -f containers/dorado.sif ]; then
    apptainer pull  $path_to_d2_map_root/containers/dorado.sif docker://nanoporetech/dorado@sha256:6156fdbb48ff13fbb141b4f1fc6e6300f05221ecfdd114fc8323a0e38296c1dd
else
    echo "dorado.sif already exists. use --force if replacement needed"
fi

if [ ! -f containers/multiqc.sif ]; then
    apptainer pull $path_to_d2_map_root/containers/multiqc.sif docker://multiqc/multiqc@sha256:a23ffc66f702b7d426634a8daa5314107f996fa0a93ae976b755531a992ebd61
else
    echo "multiqc.sif already exists. use --force if replacement needed"
fi

if [ ! -f containers/modkit_v6_bedtools.sif ]; then 
    apptainer build --fakeroot $path_to_d2_map_root/containers/modkit_v6_bedtools.sif containers/modkit_bedtools.def
else
    echo "modkit_v6_bedtools.sif already exists. use --force if replacement needed"
fi

if [ ! -f containers/R_extended.sif ]; then
    apptainer build --fakeroot $path_to_d2_map_root/containers/R_extended.sif containers/r_base_extended.def
else
    echo "R_extended.sif already exists. use --force if replacement needed"
fi

rm -rf $APPTAINER_CACHEDIR


# micromamba env for Nextflow
if [ ! -d /micromamba/$USER/envs/nextflow_env ]; then
    echo "Nextflow environment does not exist. Creating it now..."
    source $HOME/.bashrc
    micromamba env create -f $path_to_d2_map_root/sh_scripts/nextflow_environment.yml -y
else
    echo "Nextflow environment already exists."
fi

rm -rf $TMPDIR

# windowing file generation
eval "$(micromamba shell hook --shell bash)"
micromamba activate /micromamba/$USER/envs/nextflow_env
bedtools makewindows -g $path_to_genome_folder/genome.fa.fai -w $WINDOW -s $STEP > $path_to_d2_map_root/data/windows_sliding.bed

# Fetch gene_annotation.gtf
wget -P data/  https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/gencode.v49.basic.annotation.gtf.gz