#' Data Processing Functions
#' 
#' Functions for cleaning and processing diagnostic data
#' 
#' @name data_processing
NULL

#' Gather pest diagnostic information
#' 
#' Gathers diagnostic requests, determinations, flags, and enumeration data into a single data frame
#' @param diagnostic_requests Data frame containing diagnostic requests
#' @param diagnostic_determinations Data frame containing diagnostic determinations
#' @param failed_determinations Data frame containing failed determinations
#' @param enumerated_life_stages Data frame containing enumerated life stages
#' @param pest_taxonomy Data frame containing the results from SYS2_BRG_TAXONOMY
#' @return Combined dataframe with all diagnostic information
#' @export
gather_diagnostics <- function(
  diagnostic_requests,
  diagnostic_determinations,
  failed_determinations,
  enumerated_life_stages,
  pest_taxonomy) {

  # Join determinations by DIAGNOSTIC_REQUEST_ID
    df <- diagnostic_requests |>
    dplyr::left_join(
      diagnostic_determinations, 
      by = intersect(colnames(diagnostic_requests), colnames(diagnostic_determinations))
    )

  # Join failed eterminations by DIAGNOSTIC_DETERMINATION_ID
    df <- df |>
    dplyr::left_join(
      failed_determinations,
      by = intersect(colnames(df), colnames(failed_determinations))
    )

  # Join dead and alive counts by the DIAGNOSTIC_REQUEST_ID
    df <- df |>
    dplyr::left_join(
      enumerated_life_stages,
      by = intersect(colnames(df), colnames(enumerated_life_stages))
    )

  # Join pest taxonomy information
    df <- df |>
    dplyr::left_join(pest_taxonomy,
    by = intersect(colnames(df),
    colnames(pest_taxonomy))
    )

  return(df)
}



#' Parse Final Determinations
#' 
#' Processes diagnostic results to extract the most accurate final determination
#' for each diagnostic request
#' 
#' @param data Dataframe containing diagnostic results
#' @return Processed dataframe with one row per diagnostic request
#' @export
#' @examples
#' \dontrun{
#' clean_data <- parse_final_determination(raw_data)
#' }
parse_final_determination <- function(data) {
  data %>% 
    dplyr::group_by(DIAGNOSTIC_REQUEST_ID) %>% 
    # Filter for rows that are not a failed diagnostic determination
    dplyr::filter(is.na(DIAGNOSTIC_DETERMINATION_NOT_POSSIBLE_REASON)) %>% 
    # Filter the determination type - final has the highest TYPE_ID number
    dplyr::filter(DETERMINATION_TYPE_ID == max(DETERMINATION_TYPE_ID)) %>% 
    # Filter for who ID'd it - the group_ID is a hierarchy of expertise, so take the max ID
    dplyr::filter(DETERMINED_BY_GROUP_ID == max(DETERMINED_BY_GROUP_ID)) %>% 
    # The most recent is in practice the most correct
    dplyr::filter(DETERMINATION_DATETIME == max(DETERMINATION_DATETIME))
}



#' Process NUM_SHIP column in F280 MV
#' 
#' Ensures that the NUM_SHIP column is numeric, at least 1, and when in Miami, Ft Lauderdale, or Virgin Island ports, that the value is set to 1.
#' 
#' @param data Dataframe to process
#' @return Processed dataframe with updated NUM_SHIP and new_NUM_SHIP columns
#' @export
#' 
process_num_ship <- function(data) {
  result <- data %>%
    dplyr::mutate(
      NUM_SHIP = as.numeric(NUM_SHIP),
      NUM_SHIP = dplyr::case_when(
        NUM_SHIP == 0 | is.na(NUM_SHIP) ~ 1,
        .default = NUM_SHIP
      ),
      
      new_NUM_SHIP = dplyr::case_when(
        stringr::str_detect(LOCATION, "Miami") ~ 1,
        stringr::str_detect(LOCATION, "FL Ft. Lauderdale") ~ 1,
        stringr::str_detect(LOCATION, "VI") ~ 1,
        .default = NUM_SHIP
      )
    )
  
  return(result)
}

#' Establish Quarantine Status at Port Location
#' 
#' Assesses the state code and identifies the appropriate quarantine status column to use to determine the pests quarantine status at the location of inspection
#' @param data Dataframe containing quarantine status columns and LOCATION_STATE_CODE from SYS2_BRG_LOCATION
#' @return Dataframe with new quarantine_status_at_port column and without extraneous quarantine status columns
#' @export 
get_quarantine_status <- function(data) {
  data <- data |>
    dplyr::mutate(
      quarantine_status_at_port = dplyr::case_when(
        LOCATION_STATE_CODE %in% c("HI", "GU", "AS", "MP") ~ QUARANTINE_STATUS_HAWAII,
        LOCATION_STATE_CODE %in% c("VI", "PR") ~ QUARANTINE_STATUS_PUERTO_RICO,
        .default = QUARANTINE_STATUS_CONUS
      )
    )

  data <- data |> dplyr::select(
    -QUARANTINE_STATUS_HAWAII, 
    -QUARANTINE_STATUS_PUERTO_RICO, 
    -QUARANTINE_STATUS_CONUS)
  
  return(data)
}

#' Summarize pest risk
#' 
#' Summarize risk identified in quarantine status, HLI, FNW, and OPEP lists
#' 
#' 