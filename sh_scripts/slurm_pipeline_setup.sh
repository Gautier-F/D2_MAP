#!/bin/bash
#SBATCH --job-name=D2_MAP_setup           # Nom du job
#SBATCH --output=D2_MAP_setup%j.out        # Fichier de sortie (%j est remplacé par l'ID du job)
#SBATCH --error=D2_MAP_setup_%j.err         # Fichier d'erreur
#SBATCH --qos=short         # Temps maximum d'exécution (hh:mm:ss)
#SBATCH --time=05:00:00
#SBATCH --partition=standard              # Partition (ou queue) à utiliser
#SBATCH --nodes=1                         # Nombre de nœuds
#SBATCH --ntasks=1                        # Nombre de tâches
#SBATCH --cpus-per-task=4               # Nombre de cœurs CPU par tâche
#SBATCH --mem=16G                          # Quantité de mémoire par nœud (ici 8 Go)
#SBATCH --mail-type=BEGIN,END,FAIL


path_to_genome_folder="${1}"
module load apptainer
bash sh_scripts/apptainer_images_build.sh "${path_to_genome_folder}"


