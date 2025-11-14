# Flexible F280 Data Query Function

## Summary

Replaced two separate functions (`get.port.dat` and `get.region.dat`) with a single flexible function `get_f280_data()` that handles all filtering scenarios.

## Key Improvements

### Before (Two Functions)
```r
# Had to know which function to call
get.port.dat(conn, region, port.numbers, date.start, date.end)
get.region.dat(conn, region, port.numbers, date.start, date.end)
```

### After (One Flexible Function)
```r
# Single function handles all cases
get_f280_data(conn, date_start, date_end, 
              port_numbers = NULL, 
              regions = NULL,
              commodity_types = NULL)
```

## Usage Patterns

### 1. Filter by Port Only
```r
data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
                      port_numbers = c("1801"))
```

### 2. Filter by Region Only
```r
data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
                      regions = c("Southeast"))
```

### 3. Filter by Both
```r
data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
                      port_numbers = c("1801"), 
                      regions = c("Southeast"))
```

### 4. Filter by Multiple Values
```r
data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
                      port_numbers = c("1801", "1803", "4601"))
```

### 5. No Filters (All Data)
```r
data <- get_f280_data(conn, "2024-01-01", "2024-01-31")  # Be careful!
```

### 6. Add Commodity Type Filter
```r
data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
                      port_numbers = c("1801"),
                      commodity_types = c("FRUIT", "VEG"))
```

## Technical Details

### Server-Side Filtering
All filters are applied **before** data collection using `dplyr` verbs, which `dbplyr` translates to SQL:

```r
query <- tbl(connection, "table") %>%
  filter(REPORT_DT >= date_start) %>%        # SQL WHERE clause
  filter(PORT_CD %in% port_numbers) %>%      # SQL WHERE clause
  collect()                                   # Only now data moves to R
```

This is **critical for performance** with large datasets!

### NULL Handling
- `NULL` parameters are simply skipped
- No conditional logic needed in function calls
- `if (!is.null(port_numbers))` handles the filtering internally

### Backward Compatibility
Old functions still work but show deprecation warnings:
```r
# Old code still works
get.port.dat(conn, region, port.numbers, date.start, date.end)
# Shows: "get.port.dat is deprecated. Use get_f280_data() instead."
```

## Benefits

1. **✅ Flexible** - Handles all filtering combinations
2. **✅ Efficient** - Server-side filtering reduces data transfer
3. **✅ Simple** - One function instead of multiple
4. **✅ Extensible** - Easy to add new filter parameters
5. **✅ Informative** - Prints what filters were applied
6. **✅ Safe** - Prevents accidental full-table downloads with messages

## Migration Guide

### Old Code
```r
# Port filtering
port_data <- get.port.dat(conn, region, c("1801"), "2024-01-01", "2024-12-31")

# Region filtering  
region_data <- get.region.dat(conn, "Southeast", port.numbers, "2024-01-01", "2024-12-31")
```

### New Code
```r
# Port filtering
port_data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
                           port_numbers = c("1801"))

# Region filtering
region_data <- get_f280_data(conn, "2024-01-01", "2024-12-31", 
                             regions = "Southeast")

# Or both!
combined <- get_f280_data(conn, "2024-01-01", "2024-12-31",
                          port_numbers = c("1801"),
                          regions = "Southeast")
```

## Examples

See `examples/flexible_f280_queries.R` for comprehensive usage examples.

## Notes

- The `commodity.types` variable used in old functions should be passed as `commodity_types` parameter
- Calendar year (`CY`) is calculated in R after collection (not computationally expensive)
- Function prints diagnostic messages about filters applied - helpful for debugging
