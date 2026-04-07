██████╗ ██████╗     ███╗   ███╗ █████╗ ██████╗
██╔══██╗╚════██╗    ████╗ ████║██╔══██╗██╔══██╗
██║  ██║ █████╔╝    ██╔████╔██║███████║██████╔╝
██║  ██║██╔═══╝     ██║╚██╔╝██║██╔══██║██╔═══╝
██████╔╝███████╗    ██║ ╚═╝ ██║██║  ██║██║
╚═════╝ ╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝

################################################
TO BE DONE ONLY ON FIRST USE
Note: micromamba installation is required for correct functionality (https://doc.glicid.fr/GLiCID-PUBLIC/detailled/software/environment/micromamba.html)

Navigate to the D2_MAP root directory, then copy and paste these command lines into the terminal:

chmod u+x sh_scripts/apptainer_images_build.sh
sbatch --mail-user=<your_email@adress> /sh_scripts/slurm_pipeline_setup.sh <path_to_your_genome_FOLDER>

Note: The genome folder must contain the genome index (e.g. genome.fa.fai)

This installation step may take some time. (Optionally run this in a sbatch session)
Note: 
        - the gff3 file used to annote regulatory features is from : https://ftp.ensembl.org/pub/release-114/regulation/homo_sapiens/GRCh38/annotation/Homo_sapiens.GRCh38.regulatory_features.v114.gff3.gz
        - the gtf file used to identify genes ids from regulatory element location is from: https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/gencode.v49.basic.annotation.gtf.gz

###############################################


Informations required to run D2_MAP:

Fill in the Google Sheet: https://docs.google.com/spreadsheets/d/1G-Z_hKSeBRrZWTgs5YmEhgGB0VDx2Vu4CEjCjJa3i04/edit?usp=sharing
Note: each path must be an absolute path

Download the document as .xlsx format (File => Download => Microsoft Excel)

Place the file in the input_fetching folder within the D2_MAP directory

Open a terminal and navigate to the D2_MAP directory

Run the command:
        Rscript R_scripts/input_fetching.R  

Launch the pipeline with the commands: 
        source $HOME/.bashrc
        micromamba activate /micromamba/$USER/envs/nextflow_env 
        nextflow run main.nf -params-file inputs_fetching/inputs_d2map.json


The analysis report will be available in the results/D2MAP_Report folder.