To enter the informations required to run D2_MAP:

Fill in the Google Sheet: https://docs.google.com/spreadsheets/d/1G-Z_hKSeBRrZWTgs5YmEhgGB0VDx2Vu4CEjCjJa3i04/edit?usp=sharing
Select the "editor" option and request access

Download the document as .xlsx format (File => Download => Microsoft Excel)

Place the file in the inputs_fetching folder within the D2_MAP directory

Navigate to the D2_MAP directory

Run the command:
        Rscript R_scripts/input_fetching.R

Launch the pipeline with the command:
        nextflow run main.nf -params-file inputs_fetching/inputs_d2map.json