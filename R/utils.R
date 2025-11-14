#' @importFrom magrittr %>%
NULL

# Suppress R CMD check notes about undefined global variables
utils::globalVariables(c(
  "INSPECTION_DATE", "DETERMINATION_TYPE", "SUBCATEGORY", "PEST_TAXONOMIC_NAME",
  "DIAGNOSTIC_DETERMINATION_NOT_POSSIBLE_REASON", "DETERMINATION_TYPE_ID",
  "DETERMINED_BY_GROUP_ID", "DETERMINATION_DATETIME", "DIAGNOSTIC_REQUEST_ID",
  "Scientific.name", "Common.Name", "Model", "Predicted.pest.impact.in.US",
  "Prob.pest.will.cause.high.impacts", "Prob.pest.will.cause.mod.impacts",
  "Prob.pest.will.cause.low.impacts", "Genus", "Species", "name.match",
  "% Major Invader", "% Minor Invader", "% Suitable Reported", "FNW_score",
  "Pest Type", "Pest Scientific Name", "Source", "identify.by", "HLI_score",
  "PEST_TAXONOMY_GENUS", "PEST_TAXONOMY_SPECIES", "PEST_TAXONOMY_FAMILY",
  "Predicted.pest.impact.in.US.x", "Predicted.pest.impact.in.US.y",
  "Predicted.pest.impact.in.US_2", "Predicted_pest_impact_in_US",
  "Taxon Unit Type", "Taxonomy Family", "Taxonomy Genus", "Taxonomy Species",
  "Taxon_Identification_Level", "Name in ARM", "Family", "Qualitative Impact Rating",
  "quarantine.status.at.port", "pest.risk", "PORT_OF_ENTRY_NAME",
  "INSPECTION_PATHWAY", "COMMODITY", "ORIGIN_NM", "mean.pest.risk",  "n_detections", "max.pest.risk", "min.pest.risk",
  # F280 data columns
  "PATHWAY", "FY", "MON", "REPORT_DT", "PORT_CD", "LOCATION", "REGION",
  "CTYPE_CD", "CBP_PPQ280_OBJ_ID", "QUANTITY", "NUM_SHIP", "CY",
  # Location columns
  "ID", "LOCATION_TYPE", "LOCATION_CATEGORY", "REGION_ID", "SITE",
  "LOCATION_STATE_CODE", "CBP_PORT_NUMBER", "IATA_CODE",
  # Inspection columns
  "INSPECTION_NUMBER", "CATEGORY", "PATHWAY_ID", "PORT_OF_ENTRY_ID",
  "INSPECTION_DATETIME", "INSPECTION_LOCATION_ID", "COUNTRY_OF_ORIGIN_NAME",
  # Misc
  "inspection.records", "INSPECTION_ID"
))
