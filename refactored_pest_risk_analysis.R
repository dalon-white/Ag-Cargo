#' Refactored Pest Risk Lists - Using New Package Structure
#' 
#' This demonstrates how your existing pest risk lists.Rmd can be simplified
#' using the new AgCargoPestRisk package

# Load the package (once it's built)
# library(AgCargoPestRisk)

# For now, source the functions directly during development
source("R/database_functions.R")
source("R/data_processing.R") 
source("R/risk_assessment.R")
source("R/analysis_functions.R")
source("R/pipeline.R")

# Load required libraries
library(dplyr)
library(magrittr)
library(readr)

# Set parameters (from your YAML header)
params <- list(
  quarantine.pest.value = 0.5,
  uncategorized.pest.value = 0.25,
  nonquarantine.pest.value = 0,
  caps.national.priority.pest.score = 1,
  opep.noncandidate.pest.score = 0.3,
  ppq.program.pest.score = 1,
  ppq.select.agents.score = 1,
  begin_date = "2019-10-01",
  end_date = "2025-04-01"
)

# OPTION 1: Use the complete pipeline (simplest approach)
# ======================================================
message("Running complete pipeline...")

results <- run_pest_risk_pipeline(
  begin_date = params$begin_date,
  end_date = params$end_date,
  opep_directory = "Inputs/Data/OPEP",
  fnw_directory = "Inputs/Data/FNW",
  hli_directory = "Inputs/Data/High and low impact pests",
  quarantine_pest_value = params$quarantine.pest.value,
  uncategorized_pest_value = params$uncategorized.pest.value,
  nonquarantine_pest_value = params$nonquarantine.pest.value,
  caps_score = params$caps.national.priority.pest.score,
  opep_noncandidate_score = params$opep.noncandidate.pest.score,
  ppq_program_score = params$ppq.program.pest.score,
  select_agents_score = params$ppq.select.agents.score,
  output_dir = "outputs",
  export_results = TRUE
)

# Access the same results you had before
pathway.assessment <- results$pathway_assessment
df_diagnostic_results <- results$diagnostic_results
commodity_pest_risk <- results$commodity_pest_risk

# OPTION 2: Step-by-step approach (for more control)
# ==================================================
message("Running step-by-step approach...")

# Step 1: Connect and retrieve data (replaces your query chunks)
db_conn <- connect_db()
df_diagnostic_results_step <- get_diagnostic_results(db_conn, params$begin_date, params$end_date)

# Step 2: Get determinations and process (replaces your correction chunks)
diag_determ_records <- get_determinations(db_conn)
DBI::dbDisconnect(db_conn)

df_diagnostic_results_step <- df_diagnostic_results_step %>%
  left_join(diag_determ_records, by = intersect(colnames(df_diagnostic_results_step), colnames(diag_determ_records))) %>%
  parse_final_determination()

# Step 3: Load pest impact data (replaces your load chunks)
opep_data <- load_opep_data("Inputs/Data/OPEP")
fnw_data <- load_fnw_data("Inputs/Data/FNW", params$quarantine.pest.value)
hli_data <- load_hli_data(
  "Inputs/Data/High and low impact pests",
  caps_score = params$caps.national.priority.pest.score,
  opep_score = params$opep.noncandidate.pest.score,
  ppq_program_score = params$ppq.program.pest.score,
  select_agents_score = params$ppq.select.agents.score
)

# Step 4: Integrate risk assessments (replaces your integration chunks)
df_diagnostic_results_step <- integrate_opep_impacts(df_diagnostic_results_step, opep_data)
df_diagnostic_results_step <- integrate_fnw_impacts(df_diagnostic_results_step, fnw_data)
df_diagnostic_results_step <- integrate_hli_impacts(df_diagnostic_results_step, hli_data)

# Step 5: Calculate final risk scores (replaces your quantification chunk)
# Note: You'll need to add quarantine status determination logic here
df_diagnostic_results_step <- calculate_pest_risk(
  df_diagnostic_results_step,
  quarantine_value = params$quarantine.pest.value,
  uncategorized_value = params$uncategorized.pest.value,
  nonquarantine_value = params$nonquarantine.pest.value
)

# Step 6: Create summaries (replaces your summary chunks)
commodity_pest_risk_step <- summarize_commodity_pest_risk(df_diagnostic_results_step)
pathway_assessment_step <- create_pathway_assessment(commodity_pest_risk_step)

# Display results (same as your original output)
print("Top 10 highest risk commodity-origin combinations:")
print(pathway_assessment_step %>% head(10))

# Generate summary statistics
risk_summary <- generate_risk_summary(pathway_assessment_step)
print("Risk summary by port:")
print(risk_summary)

# Export results
export_results(pathway_assessment_step, "pathway_assessment_refactored", "outputs")
export_results(df_diagnostic_results_step, "diagnostic_results_refactored", "outputs")

message("Refactored analysis complete!")
