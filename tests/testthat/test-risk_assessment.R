test_that("pest_impact_calc_func calculates correctly", {
  # Test basic calculation
  result <- pest_impact_calc_func(50, 30)
  expected <- ((50 * 2) + 30) / 200
  expect_equal(result, expected)
  
  # Test with 100% high impact
  result_high <- pest_impact_calc_func(100, 0)
  expect_equal(result_high, 1.0)
  
  # Test with 0% impact
  result_zero <- pest_impact_calc_func(0, 0)
  expect_equal(result_zero, 0.0)
  
  # Test with moderate impact only
  result_mod <- pest_impact_calc_func(0, 50)
  expect_equal(result_mod, 0.25)
})

test_that("calculate_pest_risk applies correct hierarchy", {
  # Create test data
  test_data <- data.frame(
    pest.risk = NA,
    HLI_score = c(1, NA, NA, NA),
    FNW_score = c(0.7, 0.6, NA, NA),
    Predicted_pest_impact_in_US = c(0.8, 0.8, 0.5, NA),
    quarantine.status.at.port = c("Quarantine", "Quarantine", "Quarantine", "Non-Quarantine"),
    stringsAsFactors = FALSE
  )
  
  # Apply risk calculation
  result <- calculate_pest_risk(test_data, 
                               quarantine_value = 0.5,
                               uncategorized_value = 0.25,
                               nonquarantine_value = 0)
  
  # Check hierarchy: HLI > FNW > OPEP > quarantine status
  expect_equal(result$pest.risk[1], 1)    # HLI takes priority
  expect_equal(result$pest.risk[2], 0.6)  # FNW takes priority over OPEP
  expect_equal(result$pest.risk[3], 0.5)  # OPEP takes priority over quarantine
  expect_equal(result$pest.risk[4], 0)    # Non-quarantine default
})

test_that("calculate_pest_risk handles missing data", {
  test_data <- data.frame(
    pest.risk = NA,
    HLI_score = NA,
    FNW_score = NA,
    Predicted_pest_impact_in_US = NA,
    quarantine.status.at.port = "Unknown",
    stringsAsFactors = FALSE
  )
  
  result <- calculate_pest_risk(test_data)
  
  # Should default to 0 for unknown status
  expect_equal(result$pest.risk[1], 0)
})
