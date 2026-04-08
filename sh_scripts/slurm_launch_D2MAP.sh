#!/bin/bash
#SBATCH --job-name=D2_MAP_run           
#SBATCH --output=D2_MAP_run%j.out        
#SBATCH --error=D2_MAP_run_%j.err         
#SBATCH --qos=medium        
#SBATCH --time=2-00:00:00
#SBATCH --partition=standard              
#SBATCH --nodes=1                        
#SBATCH --ntasks=1                        
#SBATCH --cpus-per-task=1              
#SBATCH --mem=8G                          
#SBATCH --mail-type=BEGIN,END,FAIL

source $HOME/.bashrc
micromamba activate /micromamba/$USER/envs/nextflow_env
nextflow run main.nf -params-file inputs_fetching/inputs_d2map.json -resume
