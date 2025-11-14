# Port-Specific Risk Assessment Example
#
# This script demonstrates how to create a detailed risk assessment
# for a specific port using AgCargoPestRisk functions

library(AgCargoPestRisk)
library(dplyr)
library(ggplot2)

# Configuration
TARGET_PORT <- "Miami, FL"
BEGIN_DATE <- "2023-01-01"
END_DATE <- "2024-12-31"

# 1. GET DATA ----
cat("Retrieving data from database...\n")

conn <- connect_db()

diagnostic_data <- get_diagnostic_results(
  connection = conn,
  begin_date = BEGIN_DATE,
  end_date = END_DATE,
  limit = 50000
)

determination_data <- get_determinations(conn)
DBI::dbDisconnect(conn)

cat("Retrieved", nrow(diagnostic_data), "diagnostic records\n")

# 2. PROCESS DATA ----
cat("Processing diagnostic data...\n")

diagnostic_data <- diagnostic_data %>%
  left_join(determination_data, 
           by = intersect(colnames(diagnostic_data), 
                         colnames(determination_data))) %>%
  parse_final_determination() %>%
  # Add quarantine status determination
  mutate(
    quarantine.status.at.port = case_when(
      QUARANTINE_STATUS_CONUS == "Q" ~ "Quarantine",
      QUARANTINE_STATUS_CONUS == "NQ" ~ "Non-Quarantine",
      QUARANTINE_STATUS_CONUS == "U" ~ "Uncategorized",
      .default = "Unknown"
    )
  )

# 3. FILTER FOR TARGET PORT ----
cat("Filtering for", TARGET_PORT, "...\n")

port_data <- diagnostic_data %>%
  filter(PORT_OF_ENTRY_NAME == TARGET_PORT)

if (nrow(port_data) == 0) {
  stop("No data found for ", TARGET_PORT)
}

cat("Found", nrow(port_data), "records for", TARGET_PORT, "\n")

# 4. LOAD PEST IMPACT DATA ----
cat("Loading pest impact data...\n")

opep_data <- load_opep_data("Inputs/Data/OPEP")
fnw_data <- load_fnw_data("Inputs/Data/FNW")
hli_data <- load_hli_data("Inputs/Data/High and low impact pests")

# 5. INTEGRATE ASSESSMENTS ----
cat("Integrating pest assessments...\n")

port_data <- port_data %>%
  integrate_opep_impacts(opep_data) %>%
  integrate_fnw_impacts(fnw_data) %>%
  integrate_hli_impacts(hli_data) %>%
  calculate_pest_risk(
    quarantine_value = 0.5,
    uncategorized_value = 0.25,
    nonquarantine_value = 0
  )

# 6. CREATE SUMMARIES ----
cat("Creating summaries...\n")

# Commodity-origin summary
commodity_summary <- summarize_commodity_pest_risk(port_data)

# Top risks
top_risks <- commodity_summary %>%
  arrange(desc(mean.pest.risk)) %>%
  head(20)

# Pest taxonomy summary
pest_summary <- port_data %>%
  group_by(PEST_TAXONOMY_FAMILY, PEST_TAXONOMY_GENUS, PEST_TAXONOMY_SPECIES) %>%
  summarise(
    detections = n(),
    mean_risk = mean(pest.risk, na.rm = TRUE),
    commodities_affected = n_distinct(COMMODITY),
    origins = n_distinct(ORIGIN_NM),
    high_risk = sum(pest.risk >= 0.5),
    .groups = 'drop'
  ) %>%
  arrange(desc(mean_risk))

# Overall statistics
overall_stats <- data.frame(
  port = TARGET_PORT,
  date_range = paste(BEGIN_DATE, "to", END_DATE),
  total_detections = nrow(port_data),
  unique_pests = n_distinct(paste(port_data$PEST_TAXONOMY_GENUS, 
                                  port_data$PEST_TAXONOMY_SPECIES)),
  unique_commodities = n_distinct(port_data$COMMODITY),
  unique_origins = n_distinct(port_data$ORIGIN_NM),
  mean_risk_score = mean(port_data$pest.risk, na.rm = TRUE),
  high_risk_detections = sum(port_data$pest.risk >= 0.5),
  high_risk_percentage = round(100 * sum(port_data$pest.risk >= 0.5) / nrow(port_data), 1)
)

# 7. CREATE VISUALIZATIONS ----
cat("Creating visualizations...\n")

# Risk distribution
risk_dist <- ggplot(port_data, aes(x = pest.risk)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "red") +
  labs(
    title = paste("Pest Risk Score Distribution -", TARGET_PORT),
    subtitle = paste(BEGIN_DATE, "to", END_DATE),
    x = "Risk Score",
    y = "Number of Detections"
  ) +
  theme_minimal()

# Top commodity-origin combinations
top_combos_plot <- top_risks %>%
  mutate(combo = paste(COMMODITY, "-", ORIGIN_NM)) %>%
  ggplot(aes(x = reorder(combo, mean.pest.risk), y = mean.pest.risk)) +
  geom_col(aes(fill = mean.pest.risk >= 0.5)) +
  coord_flip() +
  scale_fill_manual(values = c("steelblue", "darkred"),
                   labels = c("< 0.5", ">= 0.5"),
                   name = "Risk Level") +
  labs(
    title = paste("Top 20 Risk Pathways -", TARGET_PORT),
    x = "Commodity - Origin",
    y = "Mean Risk Score"
  ) +
  theme_minimal()

# Detections over time
time_series <- port_data %>%
  mutate(month = floor_date(INSPECTION_DATE, "month")) %>%
  group_by(month) %>%
  summarise(
    detections = n(),
    mean_risk = mean(pest.risk, na.rm = TRUE),
    high_risk_count = sum(pest.risk >= 0.5),
    .groups = 'drop'
  )

time_plot <- ggplot(time_series, aes(x = month)) +
  geom_line(aes(y = detections), color = "steelblue", size = 1) +
  geom_line(aes(y = high_risk_count * 2), color = "darkred", size = 1, linetype = "dashed") +
  scale_y_continuous(
    name = "Total Detections",
    sec.axis = sec_axis(~./2, name = "High Risk Detections")
  ) +
  labs(
    title = paste("Detection Trends -", TARGET_PORT),
    x = "Month"
  ) +
  theme_minimal()

# 8. EXPORT RESULTS ----
cat("Exporting results...\n")

output_dir <- file.path("outputs", gsub("[, ]", "_", TARGET_PORT))
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

export_results(commodity_summary, paste0(gsub("[, ]", "_", TARGET_PORT), "_commodity_risks"), output_dir)
export_results(pest_summary, paste0(gsub("[, ]", "_", TARGET_PORT), "_pest_summary"), output_dir)
write.csv(overall_stats, file.path(output_dir, paste0(gsub("[, ]", "_", TARGET_PORT), "_stats.csv")), row.names = FALSE)

ggsave(file.path(output_dir, "risk_distribution.png"), risk_dist, width = 10, height = 6)
ggsave(file.path(output_dir, "top_pathways.png"), top_combos_plot, width = 12, height = 8)
ggsave(file.path(output_dir, "detection_trends.png"), time_plot, width = 12, height = 6)

# 9. PRINT SUMMARY ----
cat("\n=== PORT RISK ASSESSMENT SUMMARY ===\n")
cat("Port:", TARGET_PORT, "\n")
cat("Period:", BEGIN_DATE, "to", END_DATE, "\n\n")
cat("Total Detections:", overall_stats$total_detections, "\n")
cat("Unique Pests:", overall_stats$unique_pests, "\n")
cat("Unique Commodities:", overall_stats$unique_commodities, "\n")
cat("Unique Origins:", overall_stats$unique_origins, "\n")
cat("Mean Risk Score:", round(overall_stats$mean_risk_score, 3), "\n")
cat("High Risk Detections:", overall_stats$high_risk_detections, 
    "(", overall_stats$high_risk_percentage, "%)\n\n")

cat("Top 5 Highest Risk Pathways:\n")
print(top_risks %>% head(5) %>% select(COMMODITY, ORIGIN_NM, mean.pest.risk, n_detections))

cat("\nAll results saved to:", output_dir, "\n")
