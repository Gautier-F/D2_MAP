██████╗ ██████╗     ███╗   ███╗ █████╗ ██████╗
██╔══██╗╚════██╗    ████╗ ████║██╔══██╗██╔══██╗
██║  ██║ █████╔╝    ██╔████╔██║███████║██████╔╝
██║  ██║██╔═══╝     ██║╚██╔╝██║██╔══██║██╔═══╝
██████╔╝███████╗    ██║ ╚═╝ ██║██║  ██║██║
╚═════╝ ╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝

################################################
TO BE DONE ONLY ON FIRST USE
NB: micromamba installation is required for correct functionality (https://doc.glicid.fr/GLiCID-PUBLIC/detailled/software/environment/micromamba.html)

Navigate to the D2_MAP root directory, then copy and paste into the terminal:

chmod u+x sh_scripts/apptainer_images_build.sh
./sh_scripts/apptainer_images_build.sh

This installation step may take some time. (Optionaly run this in a tmux session)
###############################################


Informations required to run D2_MAP:

Fill in the Google Sheet: https://docs.google.com/spreadsheets/d/1G-Z_hKSeBRrZWTgs5YmEhgGB0VDx2Vu4CEjCjJa3i04/edit?usp=sharing

Download the document as .xlsx format (File => Download => Microsoft Excel)

Place the file in the input_fetching folder within the D2_MAP directory

Open a terminal and navigate to the D2_MAP directory

Run the command:
        Rscript R_scripts/input_fetching.R

Launch the pipeline with the commands: /// replace with slurm script
        source $HOME/.bashrc
        micromamba activate /micromamba/$USER/envs/nextflow_env 
        nextflow run main.nf -params-file inputs_fetching/inputs_d2map.json


The analysis report will be available in the results/D2MAP_Report folder.