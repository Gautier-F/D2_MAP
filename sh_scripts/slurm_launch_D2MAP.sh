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
#SBATCH --mem=2G                          
#SBATCH --mail-type=BEGIN,END,FAIL

source $HOME/.bashrc
micromamba activate /micromamba/$USER/envs/nextflow_env

JSON_FILE="inputs_fetching/inputs_d2map.json"
PATIENT_ID=$(grep '"patient_id"' "$JSON_FILE" | cut -d'"' -f4)

if [ -z "$PATIENT_ID" ]; then
    echo "Null input for patient id in $JSON_FILE"
    exit 1
fi



nextflow run main.nf \
        -params-file inputs_fetching/inputs_d2map.json \
        -work-dir "work-${PATIENT_ID}" \
        -name "run_${PATIENT_ID}_$(date +%H%M%S)" \
        -resume
