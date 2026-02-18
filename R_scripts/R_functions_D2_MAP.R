library(openxlsx)
library(data.table)
library(ggplot2)
library(ggrepel)
library(CMplot)

########################
########################
# extraction des différentes id contenues dans la colonne meta du dmr_enriched
meta_parsing = function(meta_split_element, id = "gene_id"){
    # id = gene_id, feature_type, gene_name
    id_meta = grep(id, meta_split_element, value = T)

    if (length(id_meta) == 0) return("None")
    else{
        id = strsplit(id_meta, id)[[1]][2]
    }
    return(id)
    }

# comptage pour fischer test
get_modified_counts = function(x){
    mod = strsplit(x, ":", fixed = TRUE)[[1]][2]
    num_mod = as.numeric(mod)
    return( num_mod )

}

# génère une df à partir d'un dmr enrichi à l'étape dmrFilteringEnrichment ( step6 ).

df_dmr_enriched = function(dmr_enriched, type = "region", cond_a, cond_b){
        # type = "region", "single"
        # extraction du nombre de comptage de base modifiées par condition:
        met_cond_a = unlist(lapply(dmr_enriched$V7, get_modified_counts)) # ! colonne V6 si la colonne strand n'apparait pas
        met_cond_b = unlist(lapply(dmr_enriched$V9, get_modified_counts))
        df = data.frame(chr = dmr_enriched$V1,
                start = dmr_enriched$V2,
                end = dmr_enriched$V3,
                score = dmr_enriched$V5,
                met_cond_a = met_cond_a,
                tot_cond_a = dmr_enriched$V8, # comptage nbr read total
                met_cond_b = met_cond_b,
                tot_cond_b = dmr_enriched$V10, 
                deltaB = dmr_enriched$V14 - dmr_enriched$V13,
                status = ifelse(
                                (dmr_enriched$V14 - dmr_enriched$V13) >= 0, 
                                paste0("Hyperméthylé ",cond_b), paste0("Hypométhylé ", cond_b)
                                )             
                )      
        # meta parsing             
        meta = dmr_enriched$V27


    # if(type == "single"){
    #     # extraction du nombre de comptage de base modifiées par condition:
    #     met_cond_1 = unlist(lapply(dmr_enriched$V7, get_modified_counts)) 
    #     met_cond_2 = unlist(lapply(dmr_enriched$V9, get_modified_counts))
    #     df = data.frame(chr = dmr_enriched$V1,
    #             start = dmr_enriched$V2,
    #             end = dmr_enriched$V3,
    #             score = dmr_enriched$V5,
    #             met_cond_1 = dmr_enriched$V7, # comptage nbr read méthylé à cette position pour la condition 1
    #             tot_cond_1 = dmr_enriched$V8, # comptage nbr read total
    #             met_cond_2 = dmr_enriched$V9,
    #             tot_cond_2 = dmr_enriched$V10, 
    #             deltaB = dmr_enriched$V14 - dmr_enriched$V13,
    #             status = ifelse((dmr_enriched$V14 - dmr_enriched$V13) > 0, 
    #                             "Hyperméthylé cond.2", "Hypométhylé cond.2")             
    #             )      
    #     # meta parsing             
    #     meta = dmr_enriched$V28
    # }
    if (type == "region"){
        meta_split = strsplit(meta, ";" )
        gene_ID = lapply(meta_split, meta_parsing, id = "gene_id")
        feature_type = lapply(meta_split, meta_parsing, id = "feature_type")
        gene_name = lapply(meta_split, meta_parsing, id = "gene_name")

        df$gene_id = gene_ID
        df$feature_type = as.factor(unlist(feature_type))
        df$gene_name = gene_name
        }

    return(df)
}

###### df volcano


fischer_test_func = function(mod_1, mod_2, non_mod_1, non_mod_2){
    m = matrix(c(mod_1, mod_2, non_mod_1, non_mod_2), nrow=2)
    ft = fisher.test(m)
    pval = ft$p.value
    return(pval)
}

df_volcano_fun = function(df_dmr, type = "region"){ 


    deltaB = df_dmr$deltaB # cond_b - cond_a cf ligne 44

    # p_adjust
    mod_a = df_dmr$met_cond_a
    tot_a = df_dmr$tot_cond_a
    non_mod_a = tot_a - mod_a
    mod_b = df_dmr$met_cond_b
    tot_b = df_dmr$tot_cond_b
    non_mod_b = tot_b - mod_b
    
    p_values = mapply(fischer_test_func, mod_a, mod_b, non_mod_a, non_mod_b)
 
    p_adjust = p.adjust(p_values, method = "BH")

    log_p_adjust = -log10(p_adjust)

    for (i in 1:length(log_p_adjust)){
        if (log_p_adjust[i] > 50) {log_p_adjust[i] = 50}
    }
    df_dmr$p_value = p_values
    df_dmr$p_adj_BH = p_adjust
    df_dmr$log_p_adjust = log_p_adjust
    df_dmr$significance = ifelse(p_adjust <= 0.05, "p_adj <= 0.05", "p_adj > 0.05")
    df_dmr$outliers_pval = FALSE
    df_dmr$outliers_pval[which(log_p_adjust > 50)] = TRUE

    df_dmr$score[which(df_dmr$score > 100)] = 100  # cap the score at 10 for better color gradient visualization
    
    if(type == "region"){
        df_dmr = df_dmr[, c(1:10, 14:18, 11:13)]
    }
    return(df_dmr)
}


#############################
#       Volcano plot        #
#############################


volcano_deltaB_p_adjust_score_v2 = function(df, label_id = "gene_id", type = "region", cond){

    # label = gene_id, feature_type, gene_name
    # type = Régions, "SingleBased"

    right_rect = data.frame(
        xmin = 0,
        xmax = Inf,
        ymin = -Inf,
        ymax = Inf,
        fill = "lightgreen",
        label_hyper = paste0(cond," cond. Hyper-methylated")
    )

    left_rect = data.frame(
        xmin = -Inf,
        xmax = 0,
        ymin = -Inf,
        ymax = Inf,
        fill = "lightblue",
        label_hypo = paste0(cond, " cond. Hypo-methylated")
    )

    df_subset = subset(df, p_adj_BH <= 0.05) # subset df aux points significatifs

    p = ggplot(df, aes(x = deltaB, y = log_p_adjust, color = score, shape = status)) +

            geom_rect(data = left_rect, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill),
                    color = NA, alpha = 0.2, inherit.aes = FALSE) +

            geom_rect(data = right_rect, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill),
                    color = NA, alpha = 0.2, inherit.aes = FALSE) +

            # Ajouter les labels des rectangles
            geom_text(data = left_rect, 
                    aes(x = xmin, y = max(df$log_p_adjust) * 0.95, label = label_hypo),
                    vjust = -3.5, hjust = 0, size = 4, color = "black",
                    fontface = "bold",
                    inherit.aes = FALSE) +

            geom_text(data = right_rect, 
                    aes(x = max(df$deltaB)-0.58 , y = max(df$log_p_adjust) * 0.95, label = label_hyper),
                    vjust = -3.5, hjust = -0.5, size = 4, color = "black",
                    fontface = "bold", 
                    inherit.aes = FALSE) +

            geom_point(size = 3) 
    if(type == "region"){

        p = p + geom_text_repel(data = df_subset,
            aes_string( x = "deltaB", y= "log_p_adjust", label = label_id ),
            vjust = 2.5, hjust = 0.5, size = 4, color = "black",
            inherit.aes = FALSE, max.overlaps = Inf
            ) 
        }



        p = p +
            # Ajouter les astérisques pour les outliers
            geom_text(data = subset(df, outliers_pval == TRUE), 
                        aes(x = deltaB, y = log_p_adjust), 
                        label = "*", size = 6, color = "black", 
                        vjust = -0.5, hjust = 0.5, inherit.aes = FALSE) +
            scale_color_gradient2(low = "white", mid = "gray", high = "red", midpoint = median(df$score)) +
            scale_shape_manual(values = c(16, 17)) +
            scale_fill_identity() + # Utiliser les couleurs définies dans rects$fill
            geom_vline(xintercept = 0, linetype = "dashed") +
            geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "blue") +
            theme_minimal() +
            labs(
                x = "deltaB",
                y = "-Log10(p_adjust)",
                color = "Score",
                shape = "",
                title = paste("DM ", ifelse(type == "region", "Regions", "Single Base"), sep = "")
            ) +
            guides(shape = "none") + # enlève la légende des points
            theme(
                plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
                axis.title.x = element_text(face = "bold"),
                axis.title.y = element_text(face = "bold"),
                legend.position = "right"
            )
    return(p)
}

# BarPlot feature_type (CTCF_binding_site, enhancer...)

barplot_feature_type = function(df){

    ggplot(df, aes(x = significance, fill = feature_type)) +
    geom_bar(stat = "count", position = "fill", width = 0.7) +

    scale_y_continuous(labels = scales::percent) +
    labs(   x = "",
            y = "Proportion",
            title = "Regulatory Region") +

    theme_minimal()+
    theme(  plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
            axis.title.x = element_text(face = "bold"),
            axis.title.y = element_text(face = "bold"),
            # axis.ticks.x = element_blank(),
            axis.text.x = element_text(face = "bold.italic", size = 11, ),
            legend.position = "right")

}


#####################
#      CMplot       #
#####################

# le CMplot est généré à partir du score de df_dmr_enriched
# la df est séparée en 2: score > 0 et score < 0 pour produire 2 plots
# NB: un score > 0 indique une hypermethylation de la condition B par rapport à la condition A

# simplification et adaptation de dmr_enriched pour CMplot:

df_cmplot_function = function(df_enriched, positivity = T){

    positive_index = which( df_enriched$deltaB>=0 )
    negative_index = which( df_enriched$deltaB<0 )

    snp = paste0("DMR", 1:nrow(df_enriched))
    chr = df_enriched$chr
    pos = df_enriched$start + 1
    deltaB = abs(df_enriched$deltaB)

    df_cmplot = data.frame(
                        SNP = snp,
                        Chromosome =  chr,
                        Position =  pos,
                        Score = deltaB
                        )
    
    if( positivity) df_cmplot = df_cmplot[positive_index, ]
    else df_cmplot = df_cmplot[negative_index, ]

    # discarding contigs not chr
    chr_rows = grep("^chr", df_cmplot$Chromosome)
    df_cmplot_trim = df_cmplot[chr_rows, ]

    return(df_cmplot_trim)
}




cmplot_pos_score_fun = function(df_cmplot_pos, cond){

    png("CMplot_region_positive_score.png", width = 8, height = 8, units = "in", res = 150) 
    CMplot(df_cmplot_pos,
        plot.type = "d",     # density plot
        col = c("green", "yellow", "red"),  # gradient de couleurs
        bin.size = 1e6,      # taille des fenêtres (1 Mb ici)
        chr.labels = NULL,   # garde noms chr1, chr2, etc.
        chr.den.col = NULL,  # pas de couleur spéciale pour chromosomes
        file = "jpg",        # type de fichier
        file.output = FALSE,
        verbose = TRUE,
        dpi = 300,
        main = paste0("Positive deltaB (", cond, " hypermethylated)" )
        )
    dev.off()
}

cmplot_neg_score_fun = function(df_cmplot_neg, cond){

    png("CMplot_region_negative_score.png", width = 8, height = 8, units = "in", res = 150)
    CMplot(df_cmplot_neg,
        plot.type = "d",     # density plot
        col = c("green", "yellow", "red"),  # gradient de couleurs
        bin.size = 1e6,      # taille des fenêtres (1 Mb ici)
        chr.labels = NULL,   # garde noms chr1, chr2, etc.
        chr.den.col = NULL,  # pas de couleur spéciale pour chromosomes
        file = "jpg",        # type de fichier
        file.output = FALSE,
        verbose = TRUE,
        dpi = 300,
        main = paste0("Negative deltaB (", cond, " hypomethylated)" )
        )
    dev.off()
}
