# ============================================================
# SAIGA RRUI-NDVI PROJECT
# 19_final_results_table.R   (rewritten in v1.3.1)
#
# Assembles the article tables for the RRUI coefficient (M1-M3) from the
# result files written by scripts 07, 08, 11-13, 16-18.
# v1.3.0 contained hard-coded, hand-typed values; every number below is now
# read from a results file, so re-running the pipeline updates the tables.
# ============================================================

library(dplyr)
library(readr)
library(openxlsx)

tab <- "results/tables/"

rd <- function(f) read_csv(file.path(tab, f), show_col_types = FALSE)

specs <- tibble::tribble(
  ~Model,                ~Specification,               ~twfe,                          ~cr2,                     ~wcb,
  "Baseline",            "RRUI",                       "11_baseline_twfe_clustered.csv", "07_baseline_CR2.csv",  "08_baseline_WCB.csv",
  "Climate",             "RRUI + climate",             "11_climate_twfe_clustered.csv",  "12_climate_CR2.csv",   "13_climate_WCB.csv",
  "Climate + livestock", "RRUI + climate + livestock", "16_final_twfe_clustered.csv",    "17_final_CR2.csv",     "18_final_WCB.csv"
)

row_for <- function(i) {
  s   <- specs[i, ]
  tw  <- rd(s$twfe) %>% filter(Variable == "RRUI")
  cr  <- rd(s$cr2)  %>% filter(Variable == "RRUI")
  wb  <- rd(s$wcb)
  rad <- wb %>% filter(grepl("Rademacher", Method))
  web <- wb %>% filter(grepl("Webb", Method))

  tibble(
    Model = s$Model,
    Specification = s$Specification,
    Beta_RRUI = tw$Estimate,
    Clustered_SE = tw$`Std. Error`,
    Clustered_p = tw$`Pr(>|t|)`,
    CR2_SE = cr$SE,
    CR2_df = cr$df_Satt,
    CR2_p = cr$p_Satt,
    WCB_Rademacher_p = rad$P_value,
    WCB_Rademacher_p_strict = rad$P_value_strict,
    WCB_Webb_p = web$P_value,
    N = 65L,
    Clusters = 5L
  )
}

article <- bind_rows(lapply(seq_len(nrow(specs)), row_for))

all_long <- bind_rows(lapply(seq_len(nrow(article)), function(i) {
  a <- article[i, ]
  tibble(
    Model = a$Model,
    Inference = c("Clustered (fixest CRV1)", "CR2 (Satterthwaite)",
                  "WCB Rademacher (exact)", "WCB Webb (exact)"),
    Beta_RRUI = a$Beta_RRUI,
    SE = c(a$Clustered_SE, a$CR2_SE, NA, NA),
    P_value = c(a$Clustered_p, a$CR2_p, a$WCB_Rademacher_p, a$WCB_Webb_p),
    N = a$N,
    Clusters = a$Clusters
  )
}))

# Final-model coefficients (M3): clustered and CR2
tw3 <- rd("16_final_twfe_clustered.csv")
cr3 <- rd("17_final_CR2.csv")
coefs <- tw3 %>%
  transmute(
    Variable = Variable,
    Estimate = Estimate,
    Clustered_SE = `Std. Error`,
    Clustered_p = `Pr(>|t|)`
  ) %>%
  left_join(
    cr3 %>% transmute(Variable, CR2_SE = SE, CR2_df = df_Satt, CR2_p = p_Satt),
    by = "Variable"
  )

wcb3 <- rd("18_final_WCB_all_coefficients.csv")
coefs <- coefs %>%
  left_join(
    wcb3 %>% filter(grepl("Rademacher", Method)) %>% transmute(Variable, WCB_Rademacher_p = P_value),
    by = "Variable"
  ) %>%
  left_join(
    wcb3 %>% filter(grepl("Webb", Method)) %>% transmute(Variable, WCB_Webb_p = P_value),
    by = "Variable"
  )

write_csv(article,  file.path(tab, "19_article_RRUI_table.csv"))
write_csv(all_long, file.path(tab, "19_all_RRUI_inference_results.csv"))
write_csv(coefs,    file.path(tab, "19_final_model_coefficients.csv"))

wb <- createWorkbook()
for (nm in c("Article_table", "All_inference", "Final_coefficients")) addWorksheet(wb, nm)
writeData(wb, "Article_table", article)
writeData(wb, "All_inference", all_long)
writeData(wb, "Final_coefficients", coefs)
saveWorkbook(wb, file.path(tab, "19_FINAL_RESULTS.xlsx"), overwrite = TRUE)

cat("\n===== ARTICLE TABLE (Table 7) =====\n")
print(as.data.frame(article), digits = 4)
cat("\nSaved: 19_article_RRUI_table.csv, 19_all_RRUI_inference_results.csv,\n",
    "       19_final_model_coefficients.csv, 19_FINAL_RESULTS.xlsx\n")
