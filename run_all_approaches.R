#' Master Pipeline Script
#' 
#' This script demonstrates three different ways to run the pest risk assessment:
#' 1. Complete automated pipeline
#' 2. Individual module execution  
#' 3. Custom modular approach for specific needs

# Load required libraries
library(dplyr)
library(readr)

# Source all package functions during development
source("R/database_functions.R")
source("R/data_processing.R")
source("R/risk_assessment.R") 
source("R/analysis_functions.R")
source("R/pipeline.R")

# Set global parameters
params <- list(
  begin_date = "2019-10-01",
  end_date = "2025-04-01",
  quarantine_pest_value = 0.5,
  uncategorized_pest_value = 0.25,
  nonquarantine_pest_value = 0,
  caps_national_priority_score = 1,
  opep_noncandidate_score = 0.3,
  ppq_program_score = 1,
  ppq_select_agents_score = 1
)

# =============================================================================
# APPROACH 1: Complete Automated Pipeline (Recommended for most users)
# =============================================================================

cat("\n=== APPROACH 1: COMPLETE AUTOMATED PIPELINE ===\n")

results_auto <- run_pest_risk_pipeline(
  begin_date = params$begin_date,
  end_date = params$end_date,
  opep_directory = "Inputs/Data/OPEP",
  fnw_directory = "Inputs/Data/FNW",
  hli_directory = "Inputs/Data/High and low impact pests",
  quarantine_pest_value = params$quarantine_pest_value,
  uncategorized_pest_value = params$uncategorized_pest_value,
  nonquarantine_pest_value = params$nonquarantine_pest_value,
  caps_score = params$caps_national_priority_score,
  opep_noncandidate_score = params$opep_noncandidate_score,
  ppq_program_score = params$ppq_program_score,
  select_agents_score = params$ppq_select_agents_score,
  output_dir = "outputs/automated_pipeline",
  export_results = TRUE
)

cat("Automated pipeline complete. Results available in results_auto list.\n")

# =============================================================================
# APPROACH 2: Individual Module Execution (For step-by-step control)
# =============================================================================

cat("\n=== APPROACH 2: INDIVIDUAL MODULE EXECUTION ===\n")

# This approach runs each module separately and saves intermediate results
# Useful for debugging, custom modifications, or when only certain steps are needed

cat("Running Module A: Data Retrieval...\n")
# You would run: rmarkdown::render("scripts/Module A.Rmd")
# For demo purposes, we'll simulate this:

# Module A equivalent
db_conn <- connect_db()
df_diagnostic_results_mod <- get_diagnostic_results(db_conn, params$begin_date, params$end_date)
diag_determ_records <- get_determinations(db_conn)
DBI::dbDisconnect(db_conn)

df_diagnostic_results_mod <- df_diagnostic_results_mod %>%
  left_join(diag_determ_records, by = intersect(colnames(df_diagnostic_results_mod), colnames(diag_determ_records))) %>%
  parse_final_determination() %>%
  mutate(quarantine.status.at.port = case_when(
    QUARANTINE_STATUS_CONUS == "Q" ~ "Quarantine",
    QUARANTINE_STATUS_CONUS == "NQ" ~ "Non-Quarantine", 
    QUARANTINE_STATUS_CONUS == "U" ~ "Uncategorized",
    .default = "Unknown"
  ))

# Save Module A output
if (!dir.exists("outputs/modular_approach")) dir.create("outputs/modular_approach", recursive = TRUE)
saveRDS(df_diagnostic_results_mod, "outputs/modular_approach/module_a_output.rds")

cat("Module A complete. Running Module B: Risk Assessment...\n")

# Module B equivalent  
opep_data <- load_opep_data("Inputs/Data/OPEP")
fnw_data <- load_fnw_data("Inputs/Data/FNW", params$quarantine_pest_value)
hli_data <- load_hli_data("Inputs/Data/High and low impact pests", 
                         params$caps_national_priority_score, params$opep_noncandidate_score,
                         params$ppq_program_score, params$ppq_select_agents_score)

df_diagnostic_results_mod <- integrate_opep_impacts(df_diagnostic_results_mod, opep_data)
df_diagnostic_results_mod <- integrate_fnw_impacts(df_diagnostic_results_mod, fnw_data)
df_diagnostic_results_mod <- integrate_hli_impacts(df_diagnostic_results_mod, hli_data)
df_diagnostic_results_mod <- calculate_pest_risk(df_diagnostic_results_mod, 
                                                params$quarantine_pest_value,
                                                params$uncategorized_pest_value,
                                                params$nonquarantine_pest_value)

# Save Module B output
saveRDS(df_diagnostic_results_mod, "outputs/modular_approach/module_b_output.rds")

cat("Module B complete. Running Module C: Analysis...\n")

# Module C equivalent
commodity_pest_risk_mod <- summarize_commodity_pest_risk(df_diagnostic_results_mod)
pathway_assessment_mod <- create_pathway_assessment(commodity_pest_risk_mod)
risk_summary_mod <- generate_risk_summary(pathway_assessment_mod)

# Export Module C results
export_results(pathway_assessment_mod, "pathway_assessment_modular", "outputs/modular_approach")
export_results(risk_summary_mod, "risk_summary_modular", "outputs/modular_approach")

cat("Module C complete. All modules finished successfully.\n")

# =============================================================================
# APPROACH 3: Custom Modular Approach (For specific use cases)
# =============================================================================

cat("\n=== APPROACH 3: CUSTOM MODULAR APPROACH ===\n")

# This approach demonstrates how to use specific functions for custom analyses
# Example: Only assess OPEP risks for a specific port

cat("Running custom analysis for Miami port only...\n")

# Get data for specific port
miami_data <- df_diagnostic_results_mod %>%
  filter(grepl("Miami", PORT_OF_ENTRY_NAME, ignore.case = TRUE))

if (nrow(miami_data) > 0) {
  # Focus only on OPEP assessments
  miami_opep <- integrate_opep_impacts(miami_data, opep_data)
  
  # Custom risk calculation (only OPEP + quarantine status)
  miami_opep <- miami_opep %>%
    mutate(custom_risk = case_when(
      !is.na(Predicted_pest_impact_in_US) ~ Predicted_pest_impact_in_US,
      quarantine.status.at.port == 'Quarantine' ~ 0.5,
      quarantine.status.at.port == 'Uncategorized' ~ 0.25,
      .default = 0
    ))
  
  # Custom summary for Miami
  miami_summary <- miami_opep %>%
    group_by(COMMODITY, ORIGIN_NM) %>%
    summarise(
      detection_count = n(),
      mean_opep_risk = mean(custom_risk, na.rm = TRUE),
      max_opep_risk = max(custom_risk, na.rm = TRUE),
      opep_pest_detections = sum(!is.na(Predicted_pest_impact_in_US)),
      .groups = 'drop'
    ) %>%
    arrange(desc(mean_opep_risk))
  
  # Export custom results
  export_results(miami_summary, "miami_opep_analysis", "outputs/custom_analysis")
  
  cat("Custom Miami analysis complete.\n")
  cat("Top 5 highest OPEP risk combinations in Miami:\n")
  print(head(miami_summary, 5))
} else {
  cat("No Miami data found in the dataset.\n")
}

# =============================================================================
# SUMMARY AND RECOMMENDATIONS
# =============================================================================

cat("\n=== SUMMARY AND RECOMMENDATIONS ===\n")
cat("Three approaches demonstrated:\n")
cat("1. Automated Pipeline: Best for routine analysis, complete workflow\n")
cat("2. Modular Execution: Best for debugging, custom modifications between steps\n") 
cat("3. Custom Analysis: Best for specific research questions, targeted assessments\n\n")

cat("For other groups integrating this toolkit:\n")
cat("- Use Approach 1 for standard pest risk assessments\n")
cat("- Use individual functions from Approaches 2-3 for custom workflows\n")
cat("- All functions are documented and can be used independently\n")
cat("- Results are saved in multiple formats (CSV, RDS) for flexibility\n\n")

cat("All outputs saved to:\n")
cat("- outputs/automated_pipeline/\n")
cat("- outputs/modular_approach/\n") 
cat("- outputs/custom_analysis/\n")

# Display final summary
cat("\nFinal Results Summary:\n")
cat("Automated pipeline results: ", nrow(results_auto$pathway_assessment), " pathway combinations\n")
cat("Modular approach results: ", nrow(pathway_assessment_mod), " pathway combinations\n")
if (exists("miami_summary")) {
  cat("Custom Miami analysis: ", nrow(miami_summary), " commodity-origin combinations\n")
}

cat("\nPipeline execution complete!\n")
