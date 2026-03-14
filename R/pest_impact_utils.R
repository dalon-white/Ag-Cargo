#' Risk Assessment Functions
#' 
#' Functions for calculating pest risk scores and matching taxonomies
#' 
#' @name risk_assessment
NULL

#' Calculate Pest Impact Score
#' 
#' Calculates expected impact based on high/moderate/low impact probabilities
#' 
#' @param high_impacts Probability of high impacts (0-100 scale)
#' @param mod_impacts Probability of moderate impacts (0-100 scale)
#' @return Impact score scaled 0-1
#' @export
#' @examples
#' pest_impact_calc_func(80, 15)
calc_pest_impact <- function(
  high_impacts,
  #default high impact weight is 1
  high_impact_weight,

  mod_impacts,
  #default mod impact weight is 0.5
  mod_impact_weight,

  low_impacts,
  #default low impact weight is 0
  low_impact_weight
  ) {
  # scaling_factor will scale the total down to 0 - 1 after the calculation arithmetically, regardless of what the final weights are;
  high_impacts = high_impacts/100
  mod_impacts = mod_impacts/100
  low_impacts = low_impacts/100

  # Final calculation, where high_impact_weight standard = 2, mod_impact_weight standard = 1, and low_impact_weight standard = 0
  impacts <- ((high_impacts * high_impact_weight) + (mod_impacts * mod_impact_weight) + (low_impacts * low_impact_weight))
  
  return(impacts)

  #The intention is to come out to a 0-1 scale
}


#' Calculate FNW Pest Impact Score
#' 
#' Calculates expected impact based on high/moderate/low impact probabilities
#' 
#' @param fnw_data A data set that contains FNW_score
#' @return An adjusted FNW score for suitable habitat left in the US
#' @export
#' @examples
adjust_FNW_pest_impact <- function(
  fnw_data
) {
  # Where fnw_data is a data set that contains FNW_score as numeric and within the range of 0 - 100
  fnw_data <- fnw_data |>
  dplyr::mutate(
    FNW_score = case_when(
      is.na(Suitable.Reported) ~ FNW_score,
      .default = FNW_score * 1 - (Suitable.Reported/100)
    )
  )
  
  #Adjust for weeds with no Weed Risk Assessment completed
  fnw_data <- fnw_data |> mutate(
    FNW_score = case_when(
      is.na(Major.Invader) ~ quarantine_pest_value,
      .default = FNW_score
    )
  )

  return(fnw_data)
}



#' Integrate OPEP Risk Scores
#' 
#' Matches diagnostic results with OPEP pest impact assessments.
#' OPEP (Offshore Pest Evaluation Program) provides predictive risk scores for exotic pests.
#' This function:
#' 1. Calculates impact scores from high/moderate/low probability ratings
#' 2. Extracts genus/species for arthropods
#' 3. Matches pests by scientific name, common name, and genus-species combinations
#' 
#' @param diagnostic_data Dataframe with diagnostic results containing TAXONOMY_GENUS, TAXONOMY_SPECIES, and PEST_TAXONOMIC_NAME columns
#' @param opep_data Raw OPEP dataframe from get_OPEP()
#' @return Diagnostic data with OPEP risk scores added in 'Predicted_pest_impact_in_US' column
#' @export
integrate_opep_impacts <- function(diagnostic_data, opep_data,
                                  high_impact_weight = 1,
                                  mod_impact_weight = 0.5,
                                  low_impact_weight = 0) {
  
  # Step 1: Clean and prepare OPEP data
  message("Processing OPEP data...")

  opep_processed <- opep_data %>%
    # Clean whitespace from names
    dplyr::mutate(
      Scientific.name = trimws(Scientific.Name),
      Common.Name = trimws(Common.Name)
    ) %>%
    # Filter out incomplete records
    dplyr::filter(
      #There shouldn't be any blank scientific names, but just in case, we will filter those out to avoid false matches
      !Scientific.Name == '',
      #Remove any records without impact ratings - OPEPs of these were not completed and there is no valid number to fill this impact score with
      !Predicted.Impact.Category %in% c('N/A', 'Undetermined')
    )
  
  # Step 3: Calculate quantitative impact scores (0-1 scale)
  # Uses the calc_OPEP_pest_impact function to weight high/moderate/low probabilities
  opep_with_scores <- opep_processed %>%
    dplyr::mutate(
      OPEP_impact_quantitative = calc_pest_impact(

        high_impacts = High.Impact.Pest,
        high_impact_weight = high_impact_weight,

        mod_impacts = Moderate.Impact.Pest,
        mod_impact_weight = mod_impact_weight,

        low_impacts = Low.Impact.Pest,
        low_impact_weight = low_impact_weight
      )
    )


  # Step 4: Create genus-species matching column for arthropods
  opep_final <- opep_with_scores %>%
    dplyr::mutate(
      name.match = paste(Genus, Species, sep = ' ')
    ) %>%
    # Select columns needed for matching (both qualitative and quantitative)
    dplyr::select(
      Scientific.Name,
      Common.Name,
      Predicted.Impact.Category,      # Qualitative (High/Moderate/Low)
      OPEP_impact_quantitative,         # Quantitative (0-1 scale)
      name.match
    )
  
  message("Matching ", nrow(diagnostic_data), " diagnostic records with OPEP data...")
    # Step 5: Match diagnostic data with OPEP using multiple strategies
  result <- diagnostic_data %>%
    # Create matching column for genus-species combination
    dplyr::mutate(
      name.match = paste(TAXONOMY_GENUS, TAXONOMY_SPECIES, sep = ' ')
    ) %>%
    # Match 1: Genus-species combination (for arthropods)
    # Filter out 'NA NA' to avoid false matches
    dplyr::left_join(
      opep_final %>% dplyr::filter(name.match != 'NA NA') %>%
        dplyr::select(name.match, Predicted.Impact.Category, OPEP_impact_quantitative),
      by = "name.match",
      suffix = c("", ".genus_species")
    ) %>%
    # Match 2: Scientific name exact match
    dplyr::left_join(
      opep_final %>% dplyr::select(Scientific.Name, Predicted.Impact.Category, OPEP_impact_quantitative),
      by = c("PEST_TAXONOMIC_NAME" = "Scientific.Name"),
      suffix = c("", ".sci_name")
    ) %>%
    # Match 3: Common name match
    dplyr::left_join(
      opep_final %>% dplyr::select(Common.Name, Predicted.Impact.Category, OPEP_impact_quantitative),
      by = c("PEST_TAXONOMIC_NAME" = "Common.Name"),
      suffix = c("", ".comm_name")
    ) %>%
    # Step 6: Coalesce matches (prioritize in order: genus-species, scientific name, common name)
    dplyr::mutate(
      # Qualitative impact (High/Moderate/Low)
      Predicted_pest_impact_in_US = dplyr::coalesce(
        Predicted.Impact.Category,           # From genus-species match
        Predicted.Impact.Category.sci_name,  # From scientific name match
        Predicted.Impact.Category.comm_name  # From common name match
      ),
      # Quantitative impact score (0-1 scale)
      OPEP_score = dplyr::coalesce(
        OPEP_impact_quantitative,                  # From genus-species match
        OPEP_impact_quantitative.sci_name,        # From scientific name match
        OPEP_impact_quantitative.comm_name        # From common name match
      )
    ) %>%
    # Keep OPEP impact columns before cleaning up (for reference/debugging)
    dplyr::mutate(
      OPEP_impact_qualitative_genus_species = Predicted.Impact.Category,
      OPEP_impact_qualitative_sci_name = Predicted.Impact.Category.sci_name,
      OPEP_impact_qualitative_comm_name = Predicted.Impact.Category.comm_name,
      OPEP_impact_quantitative_genus_species = OPEP_impact_quantitative,
      OPEP_impact_quantitative_sci_name_match = OPEP_impact_quantitative.sci_name,
      OPEP_impact_quantitative_comm_name_match = OPEP_impact_quantitative.comm_name
    ) %>%
    # Clean up intermediate matching columns only
    dplyr::select(
      -Predicted.Impact.Category,
      -Predicted.Impact.Category.sci_name,
      -Predicted.Impact.Category.comm_name,
      -OPEP_impact_quantitative,
      -OPEP_impact_quantitative.sci_name,
      -OPEP_impact_quantitative.comm_name,
      -name.match  # Remove temporary matching column
    ) |> 
    mutate(
      OPEP_score = as.numeric(OPEP_score)
    )

  # Report matching success
  opep_matches <- sum(!is.na(result$Predicted_pest_impact_in_US))
  message("Successfully matched ", opep_matches, " records with OPEP impact scores")
  
  return(result)
}


#' Integrate FNW Risk Scores
#' 
#' Matches diagnostic results with FNW pest assessments by taxonomy level
#' 
#' @param diagnostic_data Dataframe with diagnostic results
#' @param fnw_data Processed FNW dataframe
#' @return Diagnostic data with FNW risk scores added
#' @export
integrate_fnw_impacts <- function(diagnostic_data, fnw_data) {
  message("applying impact calculation function")

  # Split FNW data by taxon type
  FNW_split <- split(fnw_data, fnw_data$`Taxon.Unit.Type`)
  
  # Join each subset based on taxonomy level
  FNW_joined_list <- lapply(FNW_split, function(subset) {
    taxon_type <- subset$`Taxon.Unit.Type`[1]

    if (taxon_type == "Genus") {
      merge(diagnostic_data, subset, 
            by.x = c('TAXONOMY_FAMILY','TAXONOMY_GENUS'),
            by.y = c('Taxonomy.Family','Taxonomy.Genus'), 
            all.y = TRUE)
    } else if (taxon_type == "Species") {
      merge(diagnostic_data, subset, 
            by.x = c('TAXONOMY_GENUS','TAXONOMY_SPECIES'),
            by.y = c('Taxonomy.Genus','Taxonomy.Species'), 
            all.y = TRUE)
    } else if (taxon_type == "Subspecies") {
      merge(diagnostic_data, subset, 
            by.x = c('TAXONOMY_GENUS','TAXONOMY_SPECIES'),
            by.y = c('Taxonomy.Genus','Taxonomy.Species'), 
            all.y = TRUE)
    } else {
      # Variety level - match at genus/species
      merge(diagnostic_data, subset, 
            by.x = c('TAXONOMY_GENUS','TAXONOMY_SPECIES'),
            by.y = c('Taxonomy.Genus','Taxonomy.Species'), 
            all.y = TRUE)
    }
  })
  
  # Combine results
  FNW_final_df <- do.call(dplyr::bind_rows, FNW_joined_list) %>% 
    dplyr::rename(`Taxon_Identification_Level` = `Taxon.Unit.Type`)

  # Join back to diagnostic data
  result <- suppressMessages(
    diagnostic_data %>% 
    dplyr::left_join(FNW_final_df) %>% 
    dplyr::select(
      dplyr::all_of(colnames(diagnostic_data)),
      Source,
      `Name.in.ARM`,
      `Taxon_Identification_Level`,
      FNW_score
    )
  )
  
    # Report matching success
  FNW_matches <- sum(!is.na(result$FNW_score))
  message("Successfully matched ", FNW_matches, " records with FNW impact scores")
  
  return(result)
}

#' Integrate HLI Risk Scores
#' 
#' Matches diagnostic results with High and Low Impact pest assessments
#' 
#' @param diagnostic_data Dataframe with diagnostic results
#' @param hli_data Processed HLI dataframe
#' @return Diagnostic data with HLI risk scores added
#' @export
integrate_hli_impacts <- function(pest_taxonomy_data, hli_data) {
  # Split HLI data by identification method
  HLI_split <- split(hli_data, hli_data$identify.by)

  # Join each subset based on identification level
  HLI_joined_list <- lapply(HLI_split, function(subset) {
    identify_method <- subset$identify.by[1]
    
    if (identify_method == "pathogen name") {
      merge(pest_taxonomy_data, subset, 
            by.x = c('TAXONOMY_GENUS','TAXONOMY_SPECIES'),
            by.y = c('Genus','Species'), 
            all.y = TRUE)
    } else if (identify_method == "genus only") {
      merge(pest_taxonomy_data, subset, 
            by.x = c('TAXONOMY_FAMILY','TAXONOMY_GENUS'),
            by.y = c('Family','Genus'), 
            all.y = TRUE)
    } else {
      # Genus and species
      merge(pest_taxonomy_data, subset, 
            by.x = c('TAXONOMY_GENUS','TAXONOMY_SPECIES'),
            by.y = c('Genus','Species'), 
            all.y = TRUE)
    }
  })
  # Combine results
  HLI_final_df <- do.call(dplyr::bind_rows, HLI_joined_list)

  # Join back to diagnostic data (suppress join message)
  result <- suppressMessages(
    pest_taxonomy_data %>% 
      dplyr::left_join(HLI_final_df) %>% 
      dplyr::select(
        dplyr::all_of(colnames(pest_taxonomy_data)),
        Source,
        `Qualitative.Impact.Rating`,
        `Pest.Scientific.Name`,
        HLI_score
      )
  )
  
  # Report matching success
  HLI_matches <- sum(!is.na(result$HLI_score))
  message("Successfully matched ", HLI_matches, " records with HLI impact scores")

  return(result)
}

#' Calculate Final Pest Risk Score
#' 
#' Assigns final risk score based on priority hierarchy and quarantine status
#' 
#' @param diagnostic_data Dataframe with all risk scores integrated
#' @param quarantine_value Score for quarantine pests
#' @param uncategorized_value Score for uncategorized pests
#' @param nonquarantine_value Score for non-quarantine pests
#' @return Diagnostic data with final pest.risk scores
#' @export
parse_pest_impact <- function(diagnostic_data, quarantine_value = 0.5, 
                               uncategorized_value = 0.25, nonquarantine_value = 0) {
  result <- diagnostic_data %>%
    dplyr::mutate(
      pest_impact = dplyr::case_when(
        # Program pests are highest priority
        !is.na(HLI_score) ~ HLI_score,
        # FNW and OPEP assessments next
        !is.na(FNW_score) ~ FNW_score,
        !is.na(OPEP_score) ~ OPEP_score,
        # Default to quarantine status
        quarantine_status_at_port == 'Quarantine' ~ quarantine_value,
        quarantine_status_at_port == 'Uncategorized' ~ uncategorized_value,
        quarantine_status_at_port == 'Non-Quarantine' ~ nonquarantine_value,
        .default = 0
      )
    )
  
  return(result)
}
