To enter the informations required to run D2_MAP:

Fill in the Google Sheet: https://docs.google.com/spreadsheets/d/1G-Z_hKSeBRrZWTgs5YmEhgGB0VDx2Vu4CEjCjJa3i04/edit?usp=sharing

Download the document as .xlsx format (File => Download => Microsoft Excel)

Place the file in the input_fetching folder within the D2_MAP directory

Open a terminal and navigate to the D2_MAP directory

Run the command:
        Rscript R_scripts/input_fetching.R

Launch the pipeline with the command:
        nextflow run main.nf -params-file inputs_d2map.json