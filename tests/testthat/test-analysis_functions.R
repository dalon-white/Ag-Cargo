test_that("summarize_commodity_pest_risk groups correctly", {
  # Create test data
  test_data <- data.frame(
    PORT_OF_ENTRY_NAME = c("Miami, FL", "Miami, FL", "New York, NY"),
    INSPECTION_PATHWAY = c("Air", "Air", "Sea"),
    COMMODITY = c("Mango", "Mango", "Apple"),
    ORIGIN_NM = c("Mexico", "Mexico", "China"),
    pest.risk = c(0.5, 0.7, 0.3),
    stringsAsFactors = FALSE
  )
  
  result <- summarize_commodity_pest_risk(test_data)
  
  # Should have 2 rows (Miami Mango-Mexico grouped, NY Apple-China separate)
  expect_equal(nrow(result), 2)
  
  # Check mean calculation for grouped data
  miami_mango <- result[result$PORT_OF_ENTRY_NAME == "Miami, FL", ]
  expect_equal(miami_mango$mean.pest.risk, 0.6)  # (0.5 + 0.7) / 2
  expect_equal(miami_mango$n_detections, 2)
})

test_that("generate_risk_summary aggregates correctly", {
  # Create test pathway data
  test_pathway <- data.frame(
    PORT_OF_ENTRY_NAME = c("Miami, FL", "Miami, FL", "New York, NY"),
    COMMODITY = c("Mango", "Apple", "Apple"),
    ORIGIN_NM = c("Mexico", "Chile", "China"),
    mean.pest.risk = c(0.6, 0.3, 0.1),
    stringsAsFactors = FALSE
  )
  
  result <- generate_risk_summary(test_pathway, group_vars = "PORT_OF_ENTRY_NAME")
  
  # Should have 2 ports
  expect_equal(nrow(result), 2)
  
  # Check Miami calculations
  miami <- result[result$PORT_OF_ENTRY_NAME == "Miami, FL", ]
  expect_equal(miami$total_commodity_pathways, 2)
  expect_equal(miami$high_risk_pathways, 1)  # One >= 0.5
  expect_equal(miami$medium_risk_pathways, 1)  # One between 0.25-0.5
  expect_equal(miami$low_risk_pathways, 0)
})

test_that("export_results creates files", {
  # Create test data
  test_data <- data.frame(
    id = 1:3,
    value = c(10, 20, 30)
  )
  
  # Create temporary directory
  temp_dir <- tempdir()
  
  # Export
  paths <- export_results(test_data, "test_output", temp_dir, include_timestamp = FALSE)
  
  # Check files exist
  expect_true(file.exists(paths$csv))
  expect_true(file.exists(paths$rds))
  
  # Clean up
  unlink(paths$csv)
  unlink(paths$rds)
})
