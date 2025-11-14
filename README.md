# AgCargoPestRisk

A comprehensive R package for assessing pest risks associated with agricultural cargo imports. This toolkit provides functions for retrieving diagnostic data, integrating pest impact assessments (OPEP, FNW, HLI), and calculating risk scores for commodity-origin combinations at ports of entry.

---

## 📚 Documentation Guide

**New to this package? Start here:**

1. 📖 **[QUICK_START_CHECKLIST.md](QUICK_START_CHECKLIST.md)** - Step-by-step setup guide
2. 📊 **[VISUAL_GUIDE.md](VISUAL_GUIDE.md)** - Visual overview of structure and benefits
3. 📋 **[ORGANIZATION_SUMMARY.md](ORGANIZATION_SUMMARY.md)** - Complete feature list
4. 🔧 **[IMPROVEMENTS_GUIDE.md](IMPROVEMENTS_GUIDE.md)** - Development best practices
5. 🏗️ **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - File organization philosophy

**Quick links:**
- 🚀 [Installation](#installation)
- 💡 [Quick Start](#quick-start)
- 📦 [Package Structure](#package-structure)
- 🔗 [Integration Guide](#integration-with-other-projects)

---

## Installation

```r
# Install from local source
devtools::install_local("path/to/AgCargoPestRisk")

# Or install from GitHub (if hosted there)
# devtools::install_github("your-username/AgCargoPestRisk")
```

## Quick Start

### Complete Pipeline

Run the entire pest risk assessment pipeline with one function:

```r
library(AgCargoPestRisk)

results <- run_pest_risk_pipeline(
  begin_date = "2019-10-01",
  end_date = "2025-04-01",
  opep_directory = "Inputs/Data/OPEP",
  fnw_directory = "Inputs/Data/FNW", 
  hli_directory = "Inputs/Data/High and low impact pests"
)

# Access results
pathway_assessment <- results$pathway_assessment
risk_summary <- results$risk_summary
```

### Modular Usage

Use individual components for flexibility:

```r
# Database operations
conn <- connect_db()
diagnostic_data <- get_diagnostic_results(conn, "2024-01-01", "2024-12-31")

# Load pest impact data
opep_data <- load_opep_data("path/to/opep")
fnw_data <- load_fnw_data("path/to/fnw")

# Integrate assessments
diagnostic_data <- integrate_opep_impacts(diagnostic_data, opep_data)
diagnostic_data <- integrate_fnw_impacts(diagnostic_data, fnw_data)

# Calculate risk scores
diagnostic_data <- calculate_pest_risk(diagnostic_data)

# Summarize results
commodity_summary <- summarize_commodity_pest_risk(diagnostic_data)
```

## Package Structure

The package is organized into four main modules:

### Module A: Database Functions (`database_functions.R`)
- `connect_db()`: Connect to PPQ database
- `get_diagnostic_results()`: Retrieve diagnostic results
- `get_determinations()`: Get diagnostic determinations

### Module B: Data Processing (`data_processing.R`)
- `parse_final_determination()`: Clean diagnostic data
- `load_opep_data()`: Load and prepare OPEP data
- `load_fnw_data()`: Load and prepare FNW data
- `load_hli_data()`: Load and prepare HLI data

### Module C: Risk Assessment (`risk_assessment.R`)
- `integrate_opep_impacts()`: Match with OPEP assessments
- `integrate_fnw_impacts()`: Match with FNW assessments
- `integrate_hli_impacts()`: Match with HLI assessments
- `calculate_pest_risk()`: Calculate final risk scores

### Module D: Analysis (`analysis_functions.R`)
- `summarize_commodity_pest_risk()`: Summarize by commodity
- `create_pathway_assessment()`: Create pathway assessments
- `generate_risk_summary()`: Generate summary statistics
- `export_results()`: Export results to files

### Pipeline (`pipeline.R`)
- `run_pest_risk_pipeline()`: Complete end-to-end pipeline

## Integration with Other Projects

This package is designed for easy integration into other workflows:

```r
# Use specific functions in existing pipelines
my_data <- readr::read_csv("existing_pest_data.csv")
opep_data <- load_opep_data("path/to/opep")
enhanced_data <- integrate_opep_impacts(my_data, opep_data)

# Create custom analysis functions
create_port_report <- function(diagnostic_data, port_name) {
  diagnostic_data %>%
    filter(PORT_OF_ENTRY_NAME == port_name) %>%
    summarize_commodity_pest_risk()
}
```

## Data Requirements

The package expects the following data sources:

1. **Database Access**: Connection to PPQ AQI ARM database
2. **OPEP Data**: CSV files in specified directory
3. **FNW Data**: CSV files with WRA assessments
4. **HLI Data**: CSV files with high/low impact pest classifications

## Output

The package generates:

- **Pathway Assessment**: Risk scores by port, pathway, commodity, and origin
- **Summary Statistics**: Aggregated risk metrics by port
- **Detailed Results**: Complete diagnostic data with risk scores
- **Export Files**: CSV and RDS formats for downstream analysis

## Use Cases

- **Port Risk Assessment**: Prioritize inspection resources at specific ports
- **Commodity Screening**: Identify high-risk commodity-origin combinations
- **Policy Support**: Data-driven decisions for quarantine regulations
- **Research Integration**: Incorporate pest risk data into broader studies

## Contributing

1. Functions should include proper documentation with `@param`, `@return`, and `@examples`
2. Follow the modular structure when adding new functionality
3. Include error handling and input validation
4. Update the NAMESPACE file when adding exported functions

## License

[Specify your license here]

## Contact

For questions or support, contact: dalon.white@usda.gov