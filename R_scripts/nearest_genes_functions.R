library(rtracklayer)
library(org.Hs.eg.db)
library(openxlsx)
library(dplyr)

extract_gene_id <- function(meta_col) {
  stringr::str_match(meta_col, '(?:gene_id \"?|ID=)([^";\\s]+)')[,2]
}

# creation of a granges file for the regulatory elements

create_granges = function(feature_id, regulatory_gtf){
    feature_id_gr = regulatory_gtf[mcols(regulatory_gtf)$regulatory_feature_id == feature_id, ]
    return(feature_id_gr)
    }


# find the top3 nearest genes for a given feature_id and return a data frame with the gene names and distances

find_nearest_genes = function(feature_id_gr, gene_annotation_gtf, volcano_plot_df){
    # Note: volcano_plot_df to get the p_adj_BH
    # create a search window of 100kb around the feature_id
    search_window = resize(feature_id_gr,width = 200000, fix = "center")

    # find ovelaps between the search window and the gene annotation gtf
    overlaps = findOverlaps(search_window, gene_annotation_gtf)

    # extract the gene candidates and distances for the overlapping genes
    gene_candidates = gene_annotation_gtf[subjectHits(overlaps)]
    if (length(gene_candidates) == 0) {
        return(NULL) # Ou un data.frame vide avec les mêmes colonnes
    }
    distances = distance(feature_id_gr, gene_candidates)

    # fetch the regulatory element location
    feature_location = paste(as.character(seqnames(feature_id_gr)), ":", start(feature_id_gr), "-", end(feature_id_gr), sep = "")
    
    # cleaning volcano_plot_df (empty space in gene_id)
    # volcano_plot_df$gene_id = gsub('"', '', volcano_plot_df$gene_id)
    # volcano_plot_df$gene_id = trimws(volcano_plot_df$gene_id)
    p_adjust_BH = min(volcano_plot_df$p_adj_BH[volcano_plot_df$gene_id %in% feature_id_gr$regulatory_feature_id])
    
    # create a data frame with the gene names, distances and regulatory element location
    gene_candidates_df = data.frame(
        regulatory_feature = feature_id_gr$regulatory_feature_id,
        feature_type = feature_id_gr$feature_type,
        p_adjust_dmr = format(p_adjust_BH, scientific = T, digits = 3),
        feature_loc= feature_location,
        targeted_gene_name = gene_candidates$gene_name,
        targeted_gene_type = gene_candidates$gene_type,
        distance = distances
        )
    # sort the data frame by distance and return the top 3 nearest genes
    gene_candidates_unique = gene_candidates_df[!duplicated(gene_candidates_df$targeted_gene_name), ]
    gene_candidates_unique_sorted = gene_candidates_unique[order(gene_candidates_unique$distance), ]
    rownames(gene_candidates_unique_sorted) = 1 : dim(gene_candidates_unique_sorted)[1]

    return(head(gene_candidates_unique_sorted, 3))
}

generate_tables = function(dmr_table_path, gene_annotation_gr, df_volcano_path, type){

    # dmr to df_volcano
    dmr_enriched = read.table(
                                dmr_table_path,
                                sep = "\t",
                                header = FALSE,
                                stringsAsFactors = FALSE,
                                quote = "",
                                comment.char = "",
                                fill = TRUE
                                )
    # 
    if (nrow(dmr_enriched) == 0) {
        message("Info: dmr_table is empty. Creating empty files and exiting.")
        # create emptyfiles
        file.create(paste0("prom_hypo_", type, "_table.xlsx"))
        return(NULL)
    }

    # extract regulatory table (Note, columns may be different for single analysis) 
    # Note: take into account single_dmr_table (ncol: 28) vs region_dmr_table(ncol: 27)
    total_cols = ncol(dmr_enriched)

    regulatory_table = dmr_enriched[,(total_cols-8): total_cols]
    colnames(regulatory_table) = paste0("V", 1:9)

    # load tables
    df_volcano = read.xlsx(df_volcano_path)

    # retrieve statistically significane regulatory element dmr
    df_volcano_sig = df_volcano[df_volcano$p_adj_BH < 0.05, ]

    list_genes_sig <- character(0)
    if (nrow(df_volcano_sig) > 0) {
        list_genes_sig = df_volcano_sig$gene_id
    }

    # generate table for hypomethylated promoter
    df_prom_hypo = df_volcano_sig %>% filter(deltaB < 0, feature_type == "promoter")
    if (nrow(df_prom_hypo) > 0){

        df_prom_hypo_sort = df_prom_hypo[order(df_prom_hypo$p_adj_BH), ]
        feature_loc = paste(df_prom_hypo_sort$chr, ":", df_prom_hypo_sort$start, "-", df_prom_hypo_sort$end, sep = "")
        table_prom_hypo = cbind(df_prom_hypo_sort$gene_id,
                                df_prom_hypo_sort$feature_type,
                                format(df_prom_hypo_sort$p_adj_BH, scientific = T, digits = 3),
                                feature_loc,
                                df_prom_hypo_sort$gene_name)
        colnames(table_prom_hypo) = c("regulatory_feature", "feature_type", "p_adjust_dmr", "feature_loc", "targeted_gene_name")

        name_table_prom = paste("prom_hypo_", type, "_table.xlsx", sep = "")
        write.xlsx(table_prom_hypo, name_table_prom)
    } else {
        message("Info: No hypomethylated promoter found")
    }

    # création d'une feature_annot_gr restreinte aux reg feat sélectionnés par la DM
    starts <- as.numeric(regulatory_table$V4)
    ends   <- as.numeric(regulatory_table$V5)

    if (any(is.na(starts)) || any(is.na(ends))) {
        message("Warning: Non-numeric coordinates found in regulatory table.")
    }

    regulatory_gr = GRanges(
                        seqnames = regulatory_table$V1,
                        ranges = IRanges(start = starts, end = ends),
                        feature_type = regulatory_table$V3,
                        regulatory_feature_id = regulatory_table$V9)

    regulatory_feature_id = extract_gene_id(regulatory_gr$regulatory_feature_id)
    regulatory_gr$regulatory_feature_id = regulatory_feature_id
    regulatory_gr = unique(regulatory_gr) # remove duplicate lines

    # keep significant genes only
    regulatory_gr_sig = subset(regulatory_gr, subset = regulatory_feature_id %in% list_genes_sig)

    # generate tables for enhancers, ctcf_binding_sites and open chromatin region
    ## subsetting by feature_type
if (length(regulatory_gr_sig) > 0) {
        enhancer_gr = regulatory_gr_sig[regulatory_gr_sig$feature_type == "enhancer", ]
        ctcf_gr     = regulatory_gr_sig[regulatory_gr_sig$feature_type == "CTCF_binding_site", ]
        ocr_gr      = regulatory_gr_sig[regulatory_gr_sig$feature_type == "open_chromatin_region", ]
        
        # Fonction interne pour traiter et écrire chaque table
        process_and_save = function(gr_obj, file_prefix) {
            if (length(gr_obj) > 0) {
                list_split = split(gr_obj, seq_along(gr_obj))
                list_df = lapply(list_split, find_nearest_genes, gene_annotation_gr, df_volcano_sig)
                list_df_clean = Filter(Negate(is.null), list_df)
                
                if (length(list_df_clean) > 0) {
                    df_final = do.call(rbind, list_df_clean)
                    write.xlsx(df_final, paste0(file_prefix, "_", type, "_table.xlsx"))
                }
            } else {
                message(paste("Info: No", file_prefix, "found"))
            }
        }

        process_and_save(enhancer_gr, "enhancer")
        process_and_save(ctcf_gr, "ctcf")
        process_and_save(ocr_gr, "ocr")
        
    } else {
        message("Info: No significant regulatory features to process.")
    }
}
    # enhancer_gr = regulatory_gr_sig[regulatory_gr_sig$feature_type == "enhancer", ]
    # ctcf_gr = regulatory_gr_sig[regulatory_gr_sig$feature_type == "CTCF_binding_site"]
    # ocr_gr = regulatory_gr_sig[regulatory_gr_sig$feature_type == "open_chromatin_region"]

    # list_enhancer = split(enhancer_gr, seq_along(enhancer_gr))
    # list_ctcf = split(ctcf_gr, seq_along(ctcf_gr))
    # list_ocr = split(ocr_gr, seq_along(ocr_gr))


    # list_df_enhancer = lapply(list_enhancer, find_nearest_genes, gene_annotation_gr,  df_volcano_sig)
    # list_df_ctcf = lapply(list_ctcf, find_nearest_genes, gene_annotation_gr,  df_volcano_sig)
    # list_df_ocr = lapply(list_ocr, find_nearest_genes, gene_annotation_gr,  df_volcano_sig)

    # list_df_enhancer_clean = Filter(Negate(is.null), list_df_enhancer)
    # list_df_ctcf_clean = Filter(Negate(is.null), list_df_ctcf)
    # list_df_ocr_clean = Filter(Negate(is.null), list_df_ocr)

    # df_enhancer_final = do.call(rbind, list_df_enhancer_clean)
    # rownames(df_enhancer_final) = NULL
    # df_ctcf_final = do.call(rbind, list_df_ctcf_clean)
    # rownames(df_ctcf_final) = NULL
    # df_ocr_final = do.call(rbind, list_df_ocr_clean)
    # rownames(df_ctcf_final) = NULL

    # name_table_enhancer = paste("enhancer_", type, "_table.xlsx", sep ="")
    # write.xlsx(df_enhancer_final, name_table_enhancer)
    # name_table_ctcf = paste("ctcf_", type, "_table.xlsx", sep ="")
    # write.xlsx(df_ctcf_final, name_table_ctcf)
    # name_table_ocr = paste("ocr_", type, "_table.xlsx", sep ="")
    # write.xlsx(df_ocr_final, name_table_ocr)
# }