test_that("parse_final_determination selects correct records", {
  # Create test data with multiple determinations
  test_data <- data.frame(
    DIAGNOSTIC_REQUEST_ID = c(1, 1, 1, 2, 2),
    DIAGNOSTIC_DETERMINATION_NOT_POSSIBLE_REASON = c(NA, NA, NA, "Failed", NA),
    DETERMINATION_TYPE_ID = c(1, 2, 2, 1, 2),
    DETERMINED_BY_GROUP_ID = c(1, 1, 2, 1, 1),
    DETERMINATION_DATETIME = as.POSIXct(c(
      "2024-01-01 10:00:00",
      "2024-01-02 10:00:00",
      "2024-01-02 11:00:00",  # This should be selected for ID 1
      "2024-01-01 10:00:00",
      "2024-01-01 11:00:00"   # This should be selected for ID 2
    )),
    pest_name = c("Pest A", "Pest B", "Pest C", "Pest D", "Pest E"),
    stringsAsFactors = FALSE
  )
  
  result <- parse_final_determination(test_data)
  
  # Should have 2 rows (one per DIAGNOSTIC_REQUEST_ID)
  expect_equal(nrow(result), 2)
  
  # Check correct selections
  expect_equal(result$pest_name[result$DIAGNOSTIC_REQUEST_ID == 1], "Pest C")
  expect_equal(result$pest_name[result$DIAGNOSTIC_REQUEST_ID == 2], "Pest E")
})

test_that("load functions handle missing files gracefully", {
  # Test with non-existent directory
  expect_error(
    load_opep_data("nonexistent_directory"),
    "cannot open"
  )
})
