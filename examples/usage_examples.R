# Example: Using AgCargoPestRisk Package in External Projects
# 
# This demonstrates how other groups can incorporate the pest risk assessment
# functionality into their own pipelines

# Install and load the package (other groups would do this)
# devtools::install_local("path/to/AgCargoPestRisk")
library(AgCargoPestRisk)
library(dplyr)

# Example 1: Run the complete pipeline
# ==================================
results <- run_pest_risk_pipeline(
  begin_date = "2019-10-01",
  end_date = "2025-04-01",
  opep_directory = "Inputs/Data/OPEP",
  fnw_directory = "Inputs/Data/FNW", 
  hli_directory = "Inputs/Data/High and low impact pests",
  output_dir = "my_custom_outputs"
)

# Access specific results
pathway_data <- results$pathway_assessment
risk_stats <- results$risk_summary

# Example 2: Use individual components (modular approach)
# ======================================================

# Connect to database and get data
conn <- connect_db()
diagnostic_data <- get_diagnostic_results(conn, "2024-01-01", "2024-12-31")

# Process determinations
determ_data <- get_determinations(conn)
DBI::dbDisconnect(conn)

# Clean data
diagnostic_data <- diagnostic_data %>%
  left_join(determ_data, by = intersect(colnames(diagnostic_data), colnames(determ_data))) %>%
  parse_final_determination()

# Load specific pest impact data
opep_data <- load_opep_data("path/to/opep")
fnw_data <- load_fnw_data("path/to/fnw")

# Integrate specific assessments (pick and choose)
diagnostic_data <- integrate_opep_impacts(diagnostic_data, opep_data)
diagnostic_data <- integrate_fnw_impacts(diagnostic_data, fnw_data)

# Calculate custom risk scores
diagnostic_data <- calculate_pest_risk(diagnostic_data, 
                                     quarantine_value = 0.6,  # Custom values
                                     uncategorized_value = 0.3)

# Create custom summaries
custom_summary <- diagnostic_data %>%
  group_by(PORT_OF_ENTRY_NAME, COMMODITY) %>%
  summarise(
    avg_risk = mean(pest.risk, na.rm = TRUE),
    high_risk_count = sum(pest.risk >= 0.5, na.rm = TRUE),
    .groups = 'drop'
  )

# Example 3: Extend with custom functions
# ======================================

# Other groups can build on top of the base functions
create_port_specific_assessment <- function(diagnostic_data, port_name) {
  diagnostic_data %>%
    filter(PORT_OF_ENTRY_NAME == port_name) %>%
    summarize_commodity_pest_risk() %>%
    arrange(desc(mean.pest.risk))
}

# Use the custom function
miami_assessment <- create_port_specific_assessment(diagnostic_data, "Miami, FL")

# Example 4: Integration with existing workflows
# ==============================================

# Other groups can integrate specific functions into their existing code
my_existing_pest_data <- readr::read_csv("my_pest_data.csv")

# Use just the OPEP matching functionality
opep_data <- load_opep_data("Inputs/Data/OPEP")
enhanced_data <- integrate_opep_impacts(my_existing_pest_data, opep_data)

# Or just the risk calculation
final_data <- calculate_pest_risk(enhanced_data)
