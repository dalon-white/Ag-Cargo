#' Complete Pest Risk Assessment Pipeline
#' 
#' Runs the complete pest risk assessment pipeline from data retrieval to analysis
#' 
#' @param begin_date Start date for data retrieval (YYYY-MM-DD format)
#' @param end_date End date for data retrieval (YYYY-MM-DD format)
#' @param opep_directory Path to OPEP data directory
#' @param fnw_directory Path to FNW data directory
#' @param hli_directory Path to HLI data directory
#' @param quarantine_pest_value Risk score for quarantine pests (default: 0.5)
#' @param uncategorized_pest_value Risk score for uncategorized pests (default: 0.25)
#' @param nonquarantine_pest_value Risk score for non-quarantine pests (default: 0)
#' @param caps_score Score for CAPS National Priority pests (default: 1)
#' @param opep_noncandidate_score Score for OPEP Non-Candidate pests (default: 0.3)
#' @param ppq_program_score Score for PPQ Program pests (default: 1)
#' @param select_agents_score Score for Select Agents (default: 1)
#' @param output_dir Directory to save results (default: "outputs")
#' @param export_results Whether to export results to files (default: TRUE)
#' @return List containing pathway assessment and summary statistics
#' @export
#' @examples
#' \dontrun{
#' results <- run_pest_risk_pipeline(
#'   begin_date = "2019-10-01",
#'   end_date = "2025-04-01",
#'   opep_directory = "Inputs/Data/OPEP",
#'   fnw_directory = "Inputs/Data/FNW", 
#'   hli_directory = "Inputs/Data/High and low impact pests"
#' )
#' }
run_pest_risk_pipeline <- function(
  begin_date,
  end_date,
  opep_directory,
  fnw_directory,
  hli_directory,
  quarantine_pest_value = 0.5,
  uncategorized_pest_value = 0.25,
  nonquarantine_pest_value = 0,
  caps_score = 1,
  opep_noncandidate_score = 0.3,
  ppq_program_score = 1,
  select_agents_score = 1,
  output_dir = "outputs",
  export_results = TRUE
) {
  
  message("Starting pest risk assessment pipeline...")
  
  # Step 1: Connect to database and retrieve data
  message("Step 1: Connecting to database and retrieving diagnostic data...")
  db_conn <- connect_db()
  
  # Get diagnostic results
  df_diagnostic_results <- get_diagnostic_results(db_conn, begin_date, end_date)
  
  # Get determination details
  diag_determ_records <- get_determinations(db_conn)
  diag_determ_records <- diag_determ_records %>%
    dplyr::filter(DIAGNOSTIC_DETERMINATION_ID %in% df_diagnostic_results$DIAGNOSTIC_DETERMINATION_ID)
  
  # Join and parse final determinations
  df_diagnostic_results <- df_diagnostic_results %>%
    dplyr::left_join(diag_determ_records, by = intersect(colnames(df_diagnostic_results), colnames(diag_determ_records)))
  
  df_diagnostic_results <- parse_final_determination(df_diagnostic_results)
  
  # Close database connection
  DBI::dbDisconnect(db_conn)
  
  # Step 2: Load pest impact data
  message("Step 2: Loading pest impact assessment data...")
  opep_data <- load_opep_data(opep_directory)
  fnw_data <- load_fnw_data(fnw_directory, quarantine_pest_value)
  hli_data <- load_hli_data(hli_directory, caps_score, opep_noncandidate_score, 
                           ppq_program_score, select_agents_score)
  
  # Step 3: Integrate risk assessments
  message("Step 3: Integrating pest risk assessments...")
  df_diagnostic_results <- integrate_opep_impacts(df_diagnostic_results, opep_data)
  df_diagnostic_results <- integrate_fnw_impacts(df_diagnostic_results, fnw_data)
  df_diagnostic_results <- integrate_hli_impacts(df_diagnostic_results, hli_data)
  
  # Step 4: Calculate final risk scores
  message("Step 4: Calculating final pest risk scores...")
  # Note: This assumes quarantine.status.at.port column exists
  # You may need to add quarantine status determination logic here
  df_diagnostic_results <- calculate_pest_risk(
    df_diagnostic_results, 
    quarantine_pest_value, 
    uncategorized_pest_value, 
    nonquarantine_pest_value
  )
  
  # Step 5: Summarize by commodity and create pathway assessment
  message("Step 5: Creating pathway assessment...")
  commodity_pest_risk <- summarize_commodity_pest_risk(df_diagnostic_results)
  pathway_assessment <- create_pathway_assessment(commodity_pest_risk)
  
  # Step 6: Generate summary statistics
  message("Step 6: Generating summary statistics...")
  risk_summary <- generate_risk_summary(pathway_assessment)
  
  # Step 7: Export results if requested
  if (export_results) {
    message("Step 7: Exporting results...")
    export_results(pathway_assessment, "pathway_assessment", output_dir)
    export_results(risk_summary, "risk_summary", output_dir)
    export_results(df_diagnostic_results, "detailed_diagnostic_results", output_dir)
  }
  
  message("Pipeline completed successfully!")
  
  return(list(
    pathway_assessment = pathway_assessment,
    risk_summary = risk_summary,
    diagnostic_results = df_diagnostic_results,
    commodity_pest_risk = commodity_pest_risk
  ))
}
