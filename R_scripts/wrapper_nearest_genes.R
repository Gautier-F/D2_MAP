args = commandArgs(trailingOnly = TRUE)
dmr_table_region_path= args[1]
dmr_table_single_path= args[2]
gene_annotation_path = args[3]
df_volcano_region_path = args[4]
df_volcano_single_path = args[5]

source("nearest_genes_functions.R")

gene_annotation_gr = import(gene_annotation_path)

generate_tables(dmr_table_region_path, gene_annotation_gr, df_volcano_region_path, "region")
generate_tables(dmr_table_single_path, gene_annotation_gr, df_volcano_single_path, "single")