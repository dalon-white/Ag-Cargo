# Examples of using get_f280_data() with flexible filtering
# Demonstrates all usage patterns for the new unified function

library(AgCargoPestRisk)

# Connect to database
conn <- connect_db()

# Example 1: Filter by port only ----
# Use case: Analyze a specific port
miami_data <- get_f280_data(
  connection = conn,
  date_start = "2024-01-01",
  date_end = "2024-12-31",
  port_numbers = c("1801"),  # Miami port code
  limit = 10000
)

# Example 2: Filter by region only ----
# Use case: Analyze all ports in a region
southeast_data <- get_f280_data(
  connection = conn,
  date_start = "2024-01-01",
  date_end = "2024-12-31",
  regions = c("Southeast"),
  limit = 10000
)

# Example 3: Filter by both port AND region ----
# Use case: Specific ports within a region (additional validation)
southeast_specific_ports <- get_f280_data(
  connection = conn,
  date_start = "2024-01-01",
  date_end = "2024-12-31",
  port_numbers = c("1801", "1803"),
  regions = c("Southeast"),  # Further restricts to Southeast region
  limit = 10000
)

# Example 4: Filter by multiple ports ----
# Use case: Compare several ports
multi_port_data <- get_f280_data(
  connection = conn,
  date_start = "2024-01-01",
  date_end = "2024-12-31",
  port_numbers = c("1801", "1803", "4601"),  # Miami, Ft. Lauderdale, NY
  limit = 10000
)

# Example 5: No port or region filter (all data) ----
# Use case: National analysis
# WARNING: This could be huge! Use with caution and appropriate date range
national_data <- get_f280_data(
  connection = conn,
  date_start = "2024-01-01",
  date_end = "2024-01-31",  # Just one month!
  limit = 50000
)

# Example 6: Add commodity type filter ----
# Use case: Specific commodities at specific ports
fruit_miami <- get_f280_data(
  connection = conn,
  date_start = "2024-01-01",
  date_end = "2024-12-31",
  port_numbers = c("1801"),
  commodity_types = c("FRUIT", "VEG"),  # Adjust codes as needed
  limit = 10000
)

# Example 7: Check what SQL is being sent ----
# The function prints information about filters applied
# This helps verify your query is correct
test_query <- get_f280_data(
  connection = conn,
  date_start = "2024-01-01",
  date_end = "2024-01-31",
  port_numbers = c("1801"),
  regions = c("Southeast"),
  limit = 100
)
# You'll see: "Filters applied: Ports: 1801 Regions: Southeast"

# Example 8: Conditional filtering based on user input ----
# Use case: Interactive analysis where user may or may not specify filters

analyze_data <- function(conn, dates, user_port = NULL, user_region = NULL) {
  get_f280_data(
    connection = conn,
    date_start = dates$start,
    date_end = dates$end,
    port_numbers = user_port,      # NULL if not provided
    regions = user_region,          # NULL if not provided
    limit = 10000
  )
}

# User specifies port
result1 <- analyze_data(conn, 
                       dates = list(start = "2024-01-01", end = "2024-12-31"),
                       user_port = "1801")

# User specifies neither (gets all data)
result2 <- analyze_data(conn,
                       dates = list(start = "2024-01-01", end = "2024-01-31"))

# Example 9: Progressive filtering strategy ----
# Use case: Start broad, then narrow down

# Step 1: Get all Southeast data
southeast_all <- get_f280_data(
  conn, "2024-01-01", "2024-12-31",
  regions = "Southeast"
)

# Step 2: Analyze which ports have most activity
port_summary <- southeast_all %>%
  group_by(PORT_CD, LOCATION) %>%
  summarise(shipments = n(), .groups = 'drop') %>%
  arrange(desc(shipments))

# Step 3: Get detailed data for top ports only
top_ports <- port_summary$PORT_CD[1:5]
detailed_data <- get_f280_data(
  conn, "2024-01-01", "2024-12-31",
  port_numbers = top_ports
)

# Always close connection when done
DBI::dbDisconnect(conn)

# Key Benefits of this approach:
# 1. Single function handles all scenarios
# 2. Server-side filtering keeps data transfer minimal
# 3. Flexible - can add more filters as needed
# 4. Self-documenting with messages about what filters were applied
# 5. Backward compatible with deprecated functions
