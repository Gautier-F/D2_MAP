args = commandArgs(trailingOnly = TRUE)
dmr_table = args[1]
type = args[2]
cond_a = args[3]
cond_b = args[4]

source("R_functions_D2_MAP.R")

dmr_enriched = read.table(
                            dmr_table,
                            sep = "\t",
                            header = FALSE,
                            stringsAsFactors = FALSE,
                            quote = "",
                            comment.char = "",
                            fill = TRUE
                            )                                                                                                                                                           

df_dmr = df_dmr_enriched(dmr_enriched, type, cond_a, cond_b)

df_volcano = df_volcano_fun(df_dmr, type)



name_xlsx = paste("dmr_", type, "_table.xlsx", sep = "")

write.xlsx(df_volcano, name_xlsx)

label_id = "gene_id"

png(paste0("volcano_plot_", type,".png") , width = 8, height = 8, units = "in", res = 150)
volcano_deltaB_p_adjust_score_v2(df_volcano, label_id, type, cond_b)
dev.off()

if (type == "region"){
    png("barplot_feature_region.png", width = 8, height = 8, units = "in", res = 150)
    print(barplot_feature_type(df_volcano))
    dev.off()

    png("histo_dm_region_score.png", width = 8, height = 8, units = "in", res = 150)
    print(hist(dmr_enriched$V5, breaks = 100, xlab = "DM SCORE", main = ""))
    dev.off()

    ##### CMplot
    df_cmplot_pos = df_cmplot_function(df_dmr)
    df_cmplot_neg = df_cmplot_function(df_dmr, F)
    
    cmplot_pos_score_fun(df_cmplot_pos, cond_b)
    cmplot_neg_score_fun(df_cmplot_neg, cond_b)
}




