#' Database Connection Functions
#' 
#' Functions for connecting to and querying the PPQ database
#' 
#' @name database_functions
NULL

#' Connect to PPQ Database
#' 
#' Establishes connection to the PPQ AQI ARM database
#' 
#' @param database Database name (currently unused but kept for compatibility)
#' @return DBI connection object
#' @export
#' @examples
#' \dontrun{
#' conn <- connect_db()
#' }
connect_db <- function(database = NULL) {
  DBI::dbConnect(
    odbc::odbc(),
    .connection_string = paste0(
      "Driver=SQL Server;",
      "Server=AAP00VA3PPQSQL0\\MSSQLSERVER,1433;",
      "Database=PPQ_AQI_ARMDMV2;",
      "trusted_connection=yes"
    )
  )
}

connect_ppra <- function(database = NULL) {
  DBI::dbConnect(
    odbc::odbc(),
    .connection_string = paste0(
      "Driver=SQL Server;",
      "Server=AAP00VA3PPQSQL0\\MSSQLSERVER,1433;",
      "Database=PPQ_ST_PPRA;",
      "trusted_connection=yes"
    )
  )
}


#' Get Diagnostic Results (Field Operations Method)
#' 
#' Retrieves diagnostic results from the database with specified filters
#' 
#' @param connection Database connection object
#' @param begin_date Start date for filtering (YYYY-MM-DD format)
#' @param end_date End date for filtering (YYYY-MM-DD format)
#' @param limit Maximum number of records to retrieve (default: 10000)
#' @return Filtered diagnostic results dataframe
#' @export
#' @examples
#' \dontrun{
#' conn <- connect_db()
#' results <- get_diagnostic_results_FO_method(conn, "2019-10-01", "2025-04-01")
#' }
get_diagnostic_results_FO_method <- function(connection, begin_date, end_date, limit = 10000) {
  mvw_diagnostic_results <- dplyr::tbl(
    connection,
    dplyr::sql(paste0("select TOP ", limit, " * FROM [APHIS_Imports].[dbo].[mvw_Diagnostic_Results]"))
  )
  
  df_diagnostic_results <- mvw_diagnostic_results %>% 
    dplyr::filter(
      INSPECTION_DATE >= begin_date,
      INSPECTION_DATE <= end_date,
      DETERMINATION_TYPE == 'Final ID',
      SUBCATEGORY %in% c("CBP", "PIS", "SITC", "Non-PIS PPQ"),
      !is.na(PEST_TAXONOMIC_NAME)
    ) %>% 
    dplyr::collect()
  
  return(df_diagnostic_results)
}

#' Get F280 Commodity Data
#' 
#' Retrieves commodity shipment data with flexible filtering by port, region, or both.
#' Performs server-side filtering for efficiency with large datasets.
#' 
#' @param connection Database connection object
#' @param date_start Start date for filtering (YYYY-MM-DD format)
#' @param date_end End date for filtering (YYYY-MM-DD format)
#' @param port_numbers Optional vector of port codes to filter by (e.g., c("1801", "1803"))
#' @param regions Optional vector of regions to filter by (e.g., c("Southeast", "Northeast"))
#' @param commodity_types Optional vector of commodity type codes to filter by
#' @param limit Maximum number of records to retrieve (default: NULL for no limit)
#' @return Dataframe with commodity shipment data including calendar year column
#' @export
#' @examples
#' \dontrun{
#' # Get data for specific ports
#' data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
#'                       port_numbers = c("1801", "1803"))
#' 
#' # Get data for specific region
#' data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
#'                       regions = "Southeast")
#' 
#' # Get data for both port and region filters
#' data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
#'                       port_numbers = "1801", regions = "Southeast")
#' 
#' # Get all data (no port/region filter)
#' data <- get_f280_data(conn, "2024-01-01", "2024-12-31")
#' }
get_f280_data <- function(connection, 
                         date_start, 
                         date_end, 
                         port_numbers = NULL, 
                         port_regions = NULL,
                         commodity_types = NULL,
                         limit = NULL) {
  
  # Build base query with optional limit
  if (!is.null(limit)) {
    query <- dplyr::tbl(connection, 
                       dplyr::sql(paste0("SELECT TOP ", limit, " * FROM [PPQ_AQI_ARMDMV2].[AQASMSG].[F280_MV]")))
  } else {
    query <- dplyr::tbl(connection, 
                       dplyr::sql("SELECT * FROM [PPQ_AQI_ARMDMV2].[AQASMSG].[F280_MV]"))
  }
  
  # Select columns
  query <- query %>%
    dplyr::select(
      PATHWAY,
      FY,
      MON,
      REPORT_DT,
      PORT_CD, 
      LOCATION, 
      REGION,
      COMMODITY,
      CTYPE_CD,
      CBP_PPQ280_OBJ_ID,
      QUANTITY,
      ORIGIN_NM,
      NUM_SHIP
    )
  
  # Apply date filter (always applied)
  query <- query %>%
    dplyr::filter(REPORT_DT >= date_start & REPORT_DT <= date_end)
  
  # Apply commodity type filter if provided
  if (!is.null(commodity_types)) {
    query <- query %>%
      dplyr::filter(CTYPE_CD %in% commodity_types)
  }
  
  # Apply port filter if provided
  if (!is.null(port_numbers)) {
    query <- query %>%
      dplyr::filter(PORT_CD %in% port_numbers)
  }
  
  # Apply region filter if provided
  if (!is.null(port_regions)) {
    query <- query %>%
      dplyr::filter(REGION %in% port_regions)
  }
  
  # Show the SQL query being sent (helpful for debugging)
  message("Executing query...")
  message("Filters applied: ",
          ifelse(!is.null(port_numbers), paste("Ports:", paste(port_numbers, collapse=", ")), ""),
          ifelse(!is.null(port_regions), paste(" Regions:", paste(port_regions, collapse=", ")), ""),
          ifelse(!is.null(commodity_types), paste(" Commodity Types:", length(commodity_types)), ""))
  
  # Collect data from server
  result <- query %>%
    dplyr::collect()
  
  # Add calendar year column (done in R after collection)
  result <- result %>%
    dplyr::mutate(CY = lubridate::year(REPORT_DT))
  
  message("Retrieved ", nrow(result), " records")
  
  return(result)
}

# # Backward compatibility wrappers (optional - for existing code)
# #' @keywords internal
# get.port.dat <- function(connection, region, port.numbers, date.start, date.end) {
#   .Deprecated("get_f280_data", 
#               msg = "get.port.dat is deprecated. Use get_f280_data() instead.")
#   get_f280_data(connection, date.start, date.end, port_numbers = port.numbers)
# }

# #' @keywords internal
# get.region.dat <- function(connection, region, port.numbers, date.start, date.end) {
#   .Deprecated("get_f280_data",
#               msg = "get.region.dat is deprecated. Use get_f280_data() instead.")
#   get_f280_data(connection, date.start, date.end, regions = region)
# }





#' Get Inspection Data
#' 
#' @param connection Database connection object
#' @param date_start
#' @param date_end
#' @param limit A value limit to shorten download times while testing; do not use in production
#' @param origin_country A filter to limit origin_country; this is provided by f280 data fra
#' # commodity cannot be filtered by date time or country of origin; need inspection table to do that
# get_inspection_id will by fitlered by date time and provide a list of inspection IDs to filter for commodities; other filtering will occur for commodities
# NOTE TO SELF: THIS FUNCTION SHOULD FOCUS ON FILTERING DATETIME AND COUNTRY
get_inspections = function(connection,
                          date_start = begin_date,
                          date_end = end_date,
                          limit = NULL,
                          #Where origin_country == countries identified in f280, or elsewhere
                          origin_country = NULL){ 
  # Build base query with optional limit
  if (!is.null(limit)) {
    query <- dplyr::tbl(connection, 
                       dplyr::sql(paste0("SELECT TOP ", limit, " * FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_FACT_INSPECTION]")))
  } else {
    query <- dplyr::tbl(connection, 
                       dplyr::sql("SELECT * FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_FACT_INSPECTION]"))
  }
  
  
  # Select columns
  query <- query |>
    dplyr::select(
      "ID", 
  "INSPECTION_NUMBER", 
  "CATEGORY", 
  "SUBCATEGORY", 
  "PATHWAY_ID", 
  "PATHWAY",
  "PORT_OF_ENTRY_ID",
  
  "INSPECTION_DATETIME",
  "INSPECTION_LOCATION_ID",
  "COUNTRY_OF_ORIGIN_NAME")

  # Apply origin country filter if provided
  if (!is.null(origin_country)) {
    query <- query %>%
      dplyr::filter(COUNTRY_OF_ORIGIN_NAME %in% origin_country)
  }

  # Apply date filter (always applied)
  query <- query %>%
    dplyr::filter(INSPECTION_DATETIME >= date_start & INSPECTION_DATETIME <= date_end)

  # Collect data from server
  result <- query %>%
    dplyr::collect() |>
    dplyr::rename("INSPECTION_ID" = "ID")
  
  message("Retrieved ", nrow(result), " inspection IDs. These are the inspection IDs that fit the time frame and any specified country of origin")
  message("The next step is to identify records by the commodities bridge table...")
  
  return(result)
}


#' Get ARM inspection IDs to use to filter commodity records
#' 
#' @param ids Where ids = a vector of inspection IDs to filter the ARM SYS2_FACT_INSPECTION$ID column with. Within the pipeline, this is a combination of inspection_id and 
get_inspection_ids = function(inspection_records){
  inspection_records |> pull(INSPECTION_ID)
}



#' Get Commodity Data
#' 
#' @param connection Database connection object
#' @param commodities A vector of commodity names to filter by (common or display names); In the native pipeline, commodities are extracted from F280 and re-used here. the F280 help to reduce the number of commodities that are being looked for in this table; commodities can also be provided explicitly when used outside of the native pipeline
#' @param commodity_types A vector of commodity type codes to filter by; e.g., c("CF","FV") for cut flower and fruits and vegetables
get_commodity = function(connection,
                         commodities = NULL,
                         commodity_types = NULL
                         ) {
    query <- tbl(connection, sql(
      "SELECT  * FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_BRG_COMMODITY]"
    ))

  # Apply commodity type filter if provided
  if (!is.null(commodity_types)) {
    query <- query %>%
      dplyr::filter(CTYPE_CD %in% commodity_types)
  }

  # Apply commodity name filter if provided
  if(!is.null(commodities)) {
    query <- query |>
      dplyr::filter(COMMODITY_COMMON_NAME %in% commodities |
                    COMMODITY_DISPLAY_NAME %in% commodities)
  }


  query <- query |>
    dplyr::select(
      ID,
      INSPECTION_ID,
      DIAGNOSTIC_EVENT_ID,
      QUANTITY,
      QUANTITY_UNITS_NAME,
      COMMODITY_HOST_TYPE,
      DISPOSITION_CODE,
      CBP_COMMODITY_ID_NUMBER,
      INITIAL_COMMODITY_DISPLAY_NAME,
      INITIAL_COMMODITY_TAXONOMIC_DISPLAY_NAME,
      INITIAL_COMMODITY_COMMON_NAME,
      COMMODITY_DISPLAY_NAME,
      COMMODITY_TAXONOMIC_DISPLAY_NAME,
      COMMODITY_COMMON_NAME,
      TAXON_SIMPLE_NAME,
      PROPAGATIVE_MATERIAL_TYPE,
      FINAL_TAXON_SIMPLE_NAME,
      DESTINATION_CITY,
      SHIPMENT_IDENTIFIER_ID,
      DIAGNOSTIC_EVENT_ID,
      #COUNTRY_OF_ORIGIN_ID, #these aren't complete records
      #COUNTRY_OF_ORIGIN_NAME, #these aren't complete records
      QUARANTINE_RECOMMENDATION
    ) |> 
    collect() |> 
    rename('COMMODITY_ID' = 'ID')
}



#' Get Location data
#' 
#' @param connection Database connection object
#' @param date_start Start date for filtering (YYYY-MM-DD format)
#' @param date_end End date for filtering (YYYY-MM-DD format)
get_location <- function(connection,
                          date_start, 
                         date_end){

  query <- dplyr::tbl(connection, dplyr::sql("SELECT * FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_BRG_LOCATION]"))

  query <- query |>
            dplyr::collect() |> 
            dplyr::select(
                  ID,
                  LOCATION_TYPE,
                  LOCATION_CATEGORY,
                  REGION_ID,
                  REGION,
                  SITE,
                  LOCATION_STATE_CODE,
                  CBP_PORT_NUMBER,
                  IATA_CODE)
  
  results <- query |>
              dplyr::rename("INSPECTION_LOCATION_ID" = "ID")
  
  return(results)
}


#' Merge Commmodity, inspection ID, and location
#' 
#' @param commodity_df A dataframe output from SYS2_BRG_COMMODITY
#' @param inspection_df A dataframe output from SYS2_FACT_INSPECTION
#' @param location_df A dataframe output from SYS2_BRG_LOCATION
merge_records <- function(
  commodity_df,
  inspection_df,
  location_df
){
  #retrieve commodity records
  commodity_df |> 
  # add inspection information
    #use inner join because commodity_df hasn't been filtered by origin country or date, whereas inspection_df hasn't been filtered by commodity type
  dplyr::inner_join(inspection_df) |> 
  #Attach the CBP port number and other port info via the INSPECTION_LOCATION_ID in the FACT_INSPECTION table
  dplyr::left_join(location_df)
}


#' Get diagnostic requests (optimized with temp table approach)
#' 
#' Retrieves diagnostic requests using server-side join for optimal performance.
#' Creates a temporary table of commodity IDs on the server, then joins with diagnostic requests.
#'
#' @param connection Database connection object
#' @param shipment_records Dataframe containing COMMODITY_ID column
#' @param use_temp_table If TRUE (default), uses temp table approach (faster for large datasets). If FALSE, uses batch approach.
#' @param batch_size Maximum number of IDs per batch if using batch approach (default: 1000)
#' @return Dataframe with diagnostic request records
#' @export
get_diagnostic_requests <- function(connection, shipment_records, use_temp_table = TRUE, batch_size = 1000) {
  
  # Validate input
  if (nrow(shipment_records) == 0) {
    stop("shipment_records is empty. No commodities to query.")
  }

  if (!"COMMODITY_ID" %in% colnames(shipment_records)) {
    stop("COMMODITY_ID column not found in shipment_records. Available columns: ", 
         paste(colnames(shipment_records), collapse = ", "))
  }

  # Extract commodity IDs
  commodity_ids <- shipment_records %>% 
    dplyr::pull(COMMODITY_ID) %>%
    unique() %>%
    na.omit()
  
  if (length(commodity_ids) == 0) {
    stop("No valid COMMODITY_ID values found in shipment_records")
  }

  total_ids <- length(commodity_ids)
  message("Querying diagnostic requests for ", total_ids, " unique commodity IDs...")
  
  # Small number of IDs: use simple approach
  if (total_ids <= batch_size) {
    query <- dplyr::tbl(connection, dplyr::sql("SELECT * FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_BRG_DIAGNOSTIC_REQUEST_ARTICLE]"))
    
    result <- query %>%
      dplyr::filter(COMMODITY_ID %in% commodity_ids) %>%
      dplyr::collect()
    
    message("Retrieved ", nrow(result), " diagnostic request records")
    return(result)
  }
  
  # For large datasets, use temp table approach (much faster)
  if (use_temp_table) {
    message("Using temp table approach for optimal performance...")
    
    tryCatch({
      # Create a dataframe with unique commodity IDs
      id_df <- data.frame(COMMODITY_ID = commodity_ids)
      
      # Upload to temp table on server
      temp_table_name <- paste0("#temp_commodity_ids_", format(Sys.time(), "%Y%m%d%H%M%S"))
      message("Creating temp table: ", temp_table_name)
      
      DBI::dbWriteTable(connection, temp_table_name, id_df, temporary = TRUE, overwrite = TRUE)
      
      # Join on server side
      message("Performing server-side join...")
      result <- dplyr::tbl(connection, dplyr::sql(paste0(
        "SELECT dr.* FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_BRG_DIAGNOSTIC_REQUEST_ARTICLE] dr ",
        "INNER JOIN ", temp_table_name, " t ON dr.COMMODITY_ID = t.COMMODITY_ID"
      ))) %>%
        dplyr::collect()
      
      # Clean up temp table
      DBI::dbExecute(connection, paste0("DROP TABLE IF EXISTS ", temp_table_name))
      
      message("Retrieved ", nrow(result), " diagnostic request records using temp table join")
      return(result)
      
    }, error = function(e) {
      warning("Temp table approach failed: ", e$message, "\nFalling back to batch processing...")
      use_temp_table <<- FALSE
    })
  }
  
  # Fallback: Batch processing approach
  message("Using batch processing approach...")
  num_batches <- ceiling(total_ids / batch_size)
  message("Processing in ", num_batches, " batches...")
  
  all_results <- list()
  
  for (i in 1:num_batches) {
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, total_ids)
    
    batch_ids <- commodity_ids[start_idx:end_idx]
    
    message("  Batch ", i, "/", num_batches, ": querying ", length(batch_ids), " IDs...")
    
    query <- dplyr::tbl(connection, dplyr::sql("SELECT * FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_BRG_DIAGNOSTIC_REQUEST_ARTICLE]"))
    
    batch_result <- query %>%
      dplyr::filter(COMMODITY_ID %in% batch_ids) %>%
      dplyr::collect()
    
    all_results[[i]] <- batch_result
    message("    Retrieved ", nrow(batch_result), " records")
  }
  
  # Combine all batches
  result <- dplyr::bind_rows(all_results)
  
  message("Total retrieved: ", nrow(result), " diagnostic request records from ", num_batches, " batches")
  
  return(result)
}


#' Get Diagnostic Determinations (temp table approach)
#' 
#' Retrieves diagnostic determination data using server-side join for optimal performance.
#' Creates a temporary table of request IDs on the server, then joins with determinations.
#' 
#' @param connection Database connection object
#' @param diagnostic_request_data Data from diagnostic request table that houses a DIAGNOSTIC_REQUEST_ID
#' @return Diagnostic determinations dataframe
#' @export
#' 
get_determinations <- function(connection, diagnostic_request_data) {
  
  # Validate input
  if (nrow(diagnostic_request_data) == 0) {
    stop("diagnostic_request_data is empty. No determinations to query.")
  }
  
  if (!"DIAGNOSTIC_REQUEST_ID" %in% colnames(diagnostic_request_data)) {
    stop("DIAGNOSTIC_REQUEST_ID column not found in diagnostic_request_data. Available columns: ", 
         paste(colnames(diagnostic_request_data), collapse = ", "))
  }
  
  # Extract request IDs
  request_ids <- diagnostic_request_data %>% 
    dplyr::pull(DIAGNOSTIC_REQUEST_ID) %>%
    unique() %>%
    na.omit()
  
  if (length(request_ids) == 0) {
    stop("No valid DIAGNOSTIC_REQUEST_ID values found in diagnostic_request_data")
  }
  
  total_ids <- length(request_ids)
  message("Querying determinations for ", total_ids, " unique request IDs using temp table...")
  
  # Create a dataframe with unique request IDs
  id_df <- data.frame(DIAGNOSTIC_REQUEST_ID = request_ids)
  
  # Upload to temp table on server
  temp_table_name <- paste0("#temp_request_ids_", format(Sys.time(), "%Y%m%d%H%M%S"))
  message("Creating temp table: ", temp_table_name)
  
  DBI::dbWriteTable(connection, temp_table_name, id_df, temporary = TRUE, overwrite = TRUE)
    # Join on server side
  message("Performing server-side join...")
  result <- dplyr::tbl(connection, dplyr::sql(paste0(
    "SELECT dd.* FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_BRG_DIAGNOSTIC_DETERMINATION] dd ",
    "INNER JOIN ", temp_table_name, " t ON dd.DIAGNOSTIC_REQUEST_ID = t.DIAGNOSTIC_REQUEST_ID"
  ))) %>%
    dplyr::collect()
  
  # Clean up temp table
  DBI::dbExecute(connection, paste0("DROP TABLE IF EXISTS ", temp_table_name))
  
  message("Retrieved ", nrow(result), " determination records")
  
  # Get the actual column names from the retrieved data
  actual_cols <- colnames(result)

  # Define mandatory columns we need
  base_cols <- c(
    "ID",
    "DIAGNOSTIC_REQUEST_ID",
    "PEST_TAXON_ID",
    "PEST_TAXON_SIMPLE_NAME",
    "PEST_TAXONOMIC_NAME",
    "ID_AUTHORITY",
    "DETERMINATION_TYPE_ID",
    "DETERMINED_BY_GROUP_ID",
    "DETERMINATION_DATETIME",
    "QUARANTINE_STATUS_HAWAII",
    "QUARANTINE_STATUS_PUERTO_RICO"
  )

  # Check which quarantine status columns exist and add them
  quarantine_mainland_col <- NULL
  if ("QUARANTINE_STATUS_MAINLAND" %in% actual_cols) {
    quarantine_mainland_col <- "QUARANTINE_STATUS_MAINLAND"
  } else if ("QUARANTINE_STATUS_CONUS" %in% actual_cols) {
    quarantine_mainland_col <- "QUARANTINE_STATUS_CONUS"
  }

  # Create the final column selection list
  select_cols <- c(base_cols, quarantine_mainland_col)
  select_cols <- select_cols[!is.null(select_cols)]

  # Select the needed columns
  result <- result |>
    dplyr::select(all_of(select_cols)) |>
    rename("DIAGNOSTIC_DETERMINATION_ID" = "ID")

  # If needed, standardize column names for downstream code
  if (!is.null(quarantine_mainland_col) && quarantine_mainland_col == "QUARANTINE_STATUS_MAINLAND") {
    result <- result |> rename("QUARANTINE_STATUS_CONUS" = "QUARANTINE_STATUS_MAINLAND")
  }

  return(result)
}

#' Get Failed Diagnostic Determinations (temp table approach)
#' 
#' Retrieves records where diagnostic determination was not possible using server-side join.
#' 
#' @param connection Database connection object
#' @param diagnostic_determination_data Data from diagnostic determination table
#' @return Dataframe of failed determination records
#' @export
#' 
get_diag_determ_not_possible <- function(connection, diagnostic_determination_data) {
  
  # Validate input
  if (nrow(diagnostic_determination_data) == 0) {
    warning("diagnostic_determination_data is empty. Returning empty dataframe.")
    return(data.frame())
  }
  
  if (!"DIAGNOSTIC_DETERMINATION_ID" %in% colnames(diagnostic_determination_data)) {
    stop("DIAGNOSTIC_DETERMINATION_ID column not found in diagnostic_determination_data. Available columns: ", 
         paste(colnames(diagnostic_determination_data), collapse = ", "))
  }
  
  # Extract determination IDs
  determination_ids <- diagnostic_determination_data %>% 
    dplyr::pull(DIAGNOSTIC_DETERMINATION_ID) %>%
    unique() %>%
    na.omit()
  
  if (length(determination_ids) == 0) {
    warning("No valid ID values found in diagnostic_determination_data. Returning empty dataframe.")
    return(data.frame())
  }
  
  total_ids <- length(determination_ids)
  message("Querying failed determinations for ", total_ids, " unique determination IDs using temp table...")
  
  # Create a dataframe with unique determination IDs
  id_df <- data.frame(DIAGNOSTIC_DETERMINATION_ID = determination_ids)
  
  # Upload to temp table on server
  temp_table_name <- paste0("#temp_failed_det_ids_", format(Sys.time(), "%Y%m%d%H%M%S"))
  message("Creating temp table: ", temp_table_name)
  
  DBI::dbWriteTable(connection, temp_table_name, id_df, temporary = TRUE, overwrite = TRUE)
  
  # Join on server side
  message("Performing server-side join...")
  result <- dplyr::tbl(connection, dplyr::sql(paste0(
    "SELECT fd.* FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_BRG_DIAGNOSTIC_DETERMINATION_NOT_POSSIBLE_REASON] fd ",
    "INNER JOIN ", temp_table_name, " t ON fd.DIAGNOSTIC_DETERMINATION_ID = t.DIAGNOSTIC_DETERMINATION_ID"
  ))) %>%
    dplyr::select(ID, DIAGNOSTIC_DETERMINATION_ID, DIAGNOSTIC_DETERMINATION_NOT_POSSIBLE_REASON) |> 
    dplyr::rename("DIAG_FLAG_NOT_POSSIBLE_ID" = "ID") |>
    dplyr::collect()
  
  # Clean up temp table
  DBI::dbExecute(connection, paste0("DROP TABLE IF EXISTS ", temp_table_name))
  
  message("Retrieved ", nrow(result), " failed determination records")
  
  return(result)
}


#' Get number of dead and alive values for each determination (temp table approach)
#' 
#' Retrieves the data about life stages and whether they were dead or alive using server-side join.
#' 
#' @param connection Database connection object
#' @param diagnostic_request_data Dataframe of diagnostic requests to filter by; this comes from get_diagnostic_requests()
#' @return Dataframe with counts of dead and alive life stages
#' @export
get_dead_alive = function(connection, diagnostic_request_data) {
  
  # Validate input
  if (nrow(diagnostic_request_data) == 0) {
    warning("diagnostic_request_data is empty. Returning empty dataframe.")
    return(data.frame())
  }
  
  if (!"DIAGNOSTIC_REQUEST_ID" %in% colnames(diagnostic_request_data)) {
    stop("DIAGNOSTIC_REQUEST_ID column not found in diagnostic_request_data. Available columns: ", 
         paste(colnames(diagnostic_request_data), collapse = ", "))
  }
  
  # Extract diagnostic IDs
  diagnostic_ids <- diagnostic_request_data %>% 
    dplyr::pull(DIAGNOSTIC_REQUEST_ID) %>%
    unique() %>%
    na.omit()
  
  if (length(diagnostic_ids) == 0) {
    warning("No valid DIAGNOSTIC_REQUEST_ID values found. Returning empty dataframe.")
    return(data.frame())
  }
  
  total_ids <- length(diagnostic_ids)
  message("Querying dead/alive enumeration for ", total_ids, " unique diagnostic request IDs using temp table...")
  
  # Create a dataframe with unique diagnostic IDs
  id_df <- data.frame(DIAGNOSTIC_REQUEST_ID = diagnostic_ids)
  
  # Upload to temp table on server
  temp_table_name <- paste0("#temp_diag_req_ids_", format(Sys.time(), "%Y%m%d%H%M%S"))
  message("Creating temp table: ", temp_table_name)
  
  DBI::dbWriteTable(connection, temp_table_name, id_df, temporary = TRUE, overwrite = TRUE)
  
  # Join on server side
  message("Performing server-side join...")
  result <- dplyr::tbl(connection, dplyr::sql(paste0(
    "SELECT dr.* FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_FACT_DIAGNOSTIC_REQUEST] dr ",
    "INNER JOIN ", temp_table_name, " t ON dr.ID = t.DIAGNOSTIC_REQUEST_ID"
  ))) %>%
    dplyr::select(
      ID,
      DIAGNOSTIC_REQUEST_NUMBER,
      NUMBER_ALIVE_ADULTS,
      NUMBER_ALIVE_CYSTS,
      NUMBER_ALIVE_EGGS,
      NUMBER_ALIVE_IMMATURE,
      NUMBER_ALIVE_PUPAE,
      NUMBER_DEAD_ADULTS,
      NUMBER_DEAD_CYSTS,
      NUMBER_DEAD_EGGS,
      NUMBER_DEAD_IMMATURE,
      NUMBER_DEAD_PUPAE,
      REMARKS
    ) |>
    dplyr::rename("DIAGNOSTIC_REQUEST_ID" = "ID") |>
    dplyr::collect()
  
  # Clean up temp table
  DBI::dbExecute(connection, paste0("DROP TABLE IF EXISTS ", temp_table_name))
  
  message("Retrieved ", nrow(result), " enumeration records")
  
  return(result)
}


#' Get Pest Taxonomy
#' 
#' Retrieve the pest taxonomy information from the determination
#' 
get_pest_taxonomy <- function(
  connection,
  pest_diagnostics
) {

  pest_taxon_ids <- pest_diagnostics |> dplyr::pull(PEST_TAXON_ID)

  query <- dplyr::tbl(connection, dplyr::sql("SELECT * FROM [PPQ_AQI_ARMDMV2].[ARMDATADM].[SYS2_BRG_TAXONOMY]")) |>
    dplyr::filter(ID %in% pest_taxon_ids) |>
    dplyr::select(
      ID,
      TAXON_UNIT_TYPE,
      AQAS_PEST_ID,
      dplyr::starts_with("TAXONOMY_")
    ) |>
    dplyr::rename("PEST_TAXON_ID" = "ID") |>
    dplyr::collect()
  
  return(query)
}

#' Get FNW (Federal Noxious Weed) Data
#' 
#' Retrieves the Federal Noxious Weed list data from the PPRA database.
#' This list contains federally regulated noxious weeds.
#' 
#' @param connection Database connection object to PPRA database (use connect_ppra())
#' @return Dataframe containing FNW list data
#' @export
#' @examples
#' \dontrun{
#' ppra_conn <- connect_ppra()
#' fnw_data <- get_FNW(ppra_conn)
#' }
get_FNW <- function(connection){
  query <- dplyr::tbl(connection, dplyr::sql(
    "SELECT * FROM [PPQ_ST_PPRA].[dbo].[FNW_Data]"
  )) |>
  collect()

  # Remove 'X...' prefix from column names (artifact from Excel/CSV import)
  query <- query |>
    dplyr::rename_with(~stringr::str_remove(., "^X\\.+"), everything())
  
  #fix 'N/A's
  query$`Suitable.Reported` = replace(
    query$`Suitable.Reported`,
    query$`Suitable.Reported`=='N/A',
    NA
    )
  query$`Suitable.Reported` = as.numeric(
    query$`Suitable.Reported`)

  message("Loaded ", nrow(query), " FNW records")
  
  return(query)
}

#' Get HLI (High/Low Impact) Data
#' 
#' Retrieves the High/Low Impact data from the PPRA database.
#' This database contains host-pest associations and quarantine pest information.
#' 
#' @param connection Database connection object to PPRA database (use connect_ppra())
#' @return Dataframe containing HLI data
#' @export
#' @examples
#' \dontrun{
#' ppra_conn <- connect_ppra()
#' hli_data <- get_HLI(ppra_conn)
#' }
get_HLI <- function(connection){
  HLI.dat <- dplyr::tbl(connection, dplyr::sql(
    "SELECT * FROM [PPQ_ST_PPRA].[dbo].[HLI_Data]"
  )) |>  dplyr::collect()

  message("Loaded ", nrow(HLI.dat), " HLI records")
  message("Processing HLI data for impact scores...")
  
  # Quantify the risk score - wrapped in tryCatch
  HLI.dat.scores <- tryCatch({
    result <- HLI.dat |> 
      dplyr::mutate(HLI_score = dplyr::case_when(
        grepl('CAPS National Priority', Source) == TRUE ~ caps_national_priority_score,
        grepl('OPEP Non-Candidate', Source) == TRUE ~ opep_noncandidate_score,
        grepl('PPQ Program Pest', Source) == TRUE ~ ppq_program_score,
        grepl('Select Agents', Source) == TRUE ~ ppq_select_agents_score,
        .default = 0
      ))
    message("HLI pests given impact scores")
    result
  }, error = function(e) {
    warning("Failed to calculate HLI scores: ", e$message)
    HLI.dat
  })
  
  return(HLI.dat.scores)
}

#' Get OPEP (Off-Shore Pest Evaluation Program) Data
#' 
#' Retrieves OPEP pest risk assessment data from the PPRA database.
#' OPEP provides predictive pest impact scores for exotic pests not yet established in the US.
#' 
#' @param connection Database connection object to PPRA database (use connect_ppra())
#' @return Dataframe containing OPEP risk assessment data including predicted pest impacts
#' @export
#' @examples
#' \dontrun{
#' ppra_conn <- connect_ppra()
#' opep_data <- get_OPEP(ppra_conn)
#' }
get_OPEP <- function(connection){
  query <- dplyr::tbl(connection, dplyr::sql(
    "SELECT * FROM [PPQ_ST_PPRA].[dbo].[OPEP_Data]"
  )) |>
  #Unfinished OPEP pests should be filtered out on the data upload but there might be a problem with that step of my upload function, so lets just keep this in here for now.
  dplyr::filter(!Predicted.pest.impact.in.US %in% c('N/A','Undetermined')) |> 
  #collect the data
  dplyr::collect()
  
  #make sure the probabilities come in as numbers
  query <- query |> mutate(across(starts_with('Prob.pest'), readr::parse_number))

  return(query)
  message("Loaded", nrow(query), "OPEP records")
}

