library(openxlsx)
library(jsonlite)

# path definition
initial_options = commandArgs(trailingOnly = FALSE)
print(initial_options)
file_arg_name = "--file="
script_name = sub(file_arg_name, "", initial_options[grep(file_arg_name, initial_options)])
print(paste("script name: ", script_name))
script_dir = dirname(normalizePath(script_name)) # chemin parent
print(paste("script dir: ", script_dir))

# wd definition
path_to_D2MAP_folder = normalizePath(file.path(script_dir,".."))
print(paste("path to D2MAP: ", path_to_D2MAP_folder))
setwd(path_to_D2MAP_folder)

## data loading
path_to_inputs_folder = paste0(path_to_D2MAP_folder, "/inputs_fetching")
list_inputs_folder = list.files(path_to_inputs_folder)

inputs_sheet_name = grep("*.xlsx", list_inputs_folder, value = T)

path_to_inputs_sheet = paste0(path_to_inputs_folder, "/", inputs_sheet_name)

inputs_sheet = read.xlsx(path_to_inputs_sheet, colNames = F)

var_inputs = inputs_sheet$X2


# ## NA remove
var_inputs_narm = na.omit(var_inputs)

# ## MM identification from inputs_df
MM_masks = as.logical(var_inputs_narm[3:5])
MM_names = c("5mC", "5hmC", "6mA")
MM_inputs = MM_names[MM_masks]
MM = paste(MM_inputs, collapse = " ")

# ## remove booleans and insert MM
var_inputs_clean = var_inputs_narm[-c(3:5)]
var_inputs_MM = c(var_inputs_clean[1:2], MM, var_inputs_clean[3:10])


# ### variables naming and df generation

var_names = c(
    "patient_id",
    "analysis",
    "modified_bases",
    "path_to_bam_1",
    "cond_1",
    "path_to_bam_2",
    "cond_2",
    "path_to_ref",
    "path_to_regulatory_feature_gtf",
    "path_to_gene_annotation_gtf",
    "path_to_region",
    "dmr_score_thr"
)

inputs_df = data.frame(matrix(nrow =1, ncol = length(var_names)))
colnames(inputs_df) = var_names
inputs_df[1, ]  = var_inputs_MM


# ## conversion to JSON
inputs = as.list(inputs_df[1, ]) # permet d'enlever les crochets
inputs$dmr_score_thr = as.numeric(inputs$dmr_score_thr)

write_json(
    inputs,
    paste0(path_to_inputs_folder,"/inputs_d2map.json"),
    pretty = T,
    auto_unbox = T
)

