#' Analysis and Summarization Functions
#' 
#' Functions for summarizing pest risk data and creating pathway assessments
#' 
#' @name analysis_functions
NULL

#' Summarize Pest Risk by Commodity
#' 
#' Calculates mean pest risk scores by port, pathway, commodity, and origin
#' 
#' @param diagnostic_data Dataframe with pest risk scores
#' @return Summarized commodity pest risk dataframe
#' @export
#' @examples
#' \dontrun{
#' commodity_summary <- summarize_commodity_pest_risk(diagnostic_data)
#' }
summarize_commodity_pest_risk <- function(diagnostic_data) {
  commodity_pest_risk <- diagnostic_data %>% 
    dplyr::group_by(PORT_OF_ENTRY_NAME, INSPECTION_PATHWAY, COMMODITY, ORIGIN_NM) %>% 
    dplyr::summarise(
      mean.pest.risk = mean(pest.risk, na.rm = TRUE),
      n_detections = dplyr::n(),
      max.pest.risk = max(pest.risk, na.rm = TRUE),
      min.pest.risk = min(pest.risk, na.rm = TRUE),
      .groups = 'drop'
    )
  
  return(commodity_pest_risk)
}

#' Create Pathway Assessment
#' 
#' Combines commodity pest risk with ARM inspection data for comprehensive assessment
#' 
#' @param commodity_pest_risk Summarized commodity pest risk data
#' @param arm_data_list List of ARM datasets to join (optional)
#' @return Complete pathway assessment dataframe
#' @export
#' @examples
#' \dontrun{
#' pathway_data <- create_pathway_assessment(commodity_summary)
#' }
create_pathway_assessment <- function(commodity_pest_risk, arm_data_list = NULL) {
  # Start with base commodity risk data
  pathway_assessment <- commodity_pest_risk %>%
    dplyr::arrange(dplyr::desc(mean.pest.risk))
  
  # If ARM data is provided, join it
  if (!is.null(arm_data_list)) {
    join_keys <- c('CBP_PORT_NUMBER', 'PATHWAY', 'COMMODITY', 'ORIGIN_NM')
    
    for (dataset_name in names(arm_data_list)) {
      if (all(join_keys %in% names(arm_data_list[[dataset_name]]))) {
        pathway_assessment <- pathway_assessment %>%
          dplyr::left_join(arm_data_list[[dataset_name]], by = join_keys)
      }
    }
  }
  
  return(pathway_assessment)
}

#' Generate Risk Summary Statistics
#' 
#' Creates summary statistics for pest risk assessment
#' 
#' @param pathway_data Complete pathway assessment dataframe
#' @param group_vars Variables to group by for summary
#' @return Summary statistics dataframe
#' @export
generate_risk_summary <- function(pathway_data, group_vars = c("PORT_OF_ENTRY_NAME")) {
  pathway_data %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      total_commodity_pathways = dplyr::n(),
      mean_risk_score = mean(mean.pest.risk, na.rm = TRUE),
      high_risk_pathways = sum(mean.pest.risk >= 0.5, na.rm = TRUE),
      medium_risk_pathways = sum(mean.pest.risk >= 0.25 & mean.pest.risk < 0.5, na.rm = TRUE),
      low_risk_pathways = sum(mean.pest.risk < 0.25, na.rm = TRUE),
      max_risk_score = max(mean.pest.risk, na.rm = TRUE),
      .groups = 'drop'
    )
}

#' Export Results
#' 
#' Saves analysis results to CSV and RDS formats
#' 
#' @param data Dataframe to export
#' @param filename Base filename (without extension)
#' @param output_dir Output directory path
#' @param include_timestamp Whether to include timestamp in filename
#' @export
export_results <- function(data, filename, output_dir = "outputs", include_timestamp = TRUE) {
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Add timestamp if requested
  if (include_timestamp) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    filename <- paste0(filename, "_", timestamp)
  }
  
  # Export as CSV and RDS
  csv_path <- file.path(output_dir, paste0(filename, ".csv"))
  rds_path <- file.path(output_dir, paste0(filename, ".rds"))
  
  readr::write_csv(data, csv_path)
  saveRDS(data, rds_path)
  
  message("Data exported to:\n", csv_path, "\n", rds_path)
  
  return(list(csv = csv_path, rds = rds_path))
}
