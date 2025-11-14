# AgCargoPestRisk Project Structure

## Directory Organization

```
Ag-Cargo/
├── R/                          # Core package functions (exported)
│   ├── database_functions.R    # Database operations
│   ├── data_processing.R       # Data cleaning & preparation
│   ├── risk_assessment.R       # Risk scoring & taxonomy matching
│   ├── analysis_functions.R    # Summarization & reporting
│   ├── pipeline.R              # Complete workflow
│   └── utils.R                 # Helper functions & globals
│
├── inst/                       # Installed package files
│   ├── extdata/                # Example data files
│   ├── templates/              # Report templates
│   └── config/                 # Default configuration files
│
├── tests/                      # Unit tests
│   ├── testthat/
│   │   ├── test-database_functions.R
│   │   ├── test-risk_assessment.R
│   │   └── test-analysis_functions.R
│   └── testthat.R
│
├── vignettes/                  # Documentation & tutorials
│   ├── getting-started.Rmd     # Quick start guide
│   ├── modular-usage.Rmd       # How to use individual modules
│   └── advanced-customization.Rmd
│
├── man/                        # Auto-generated function documentation
│
├── scripts/                    # Analysis workflows (not exported)
│   ├── Module A.Rmd            # Data retrieval workflow
│   ├── Module B.Rmd            # Risk assessment workflow
│   ├── Module C.Rmd            # Analysis workflow
│   ├── inputs.yaml             # Configuration file
│   └── PestWatch.Rmd           # Custom analysis
│
├── examples/                   # Example scripts for users
│   ├── usage_examples.R        # Basic usage examples
│   ├── port_specific_analysis.R
│   └── custom_risk_scoring.R
│
├── Inputs/                     # Input data (not in package)
│   └── Data/
│       ├── OPEP/
│       ├── FNW/
│       └── High and low impact pests/
│
├── outputs/                    # Generated outputs (not in package)
│
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Exported functions
├── README.md                   # Project overview
├── NEWS.md                     # Version change log
├── .Rbuildignore              # Files to exclude from package
└── .gitignore                 # Files to exclude from git
```

## File Purposes

### Core Package (R/)
- **Exported functions** that other users/packages can call
- Well-documented with roxygen2
- Unit tested
- Stable API

### Installed Files (inst/)
- **Example datasets** for testing/demos
- **Templates** for reports
- **Config files** for default settings
- Accessible via `system.file()` after installation

### Tests (tests/)
- **Unit tests** for all exported functions
- Ensures reliability
- Catches regressions
- Required for CRAN submission

### Vignettes (vignettes/)
- **Long-form documentation**
- Workflow tutorials
- Best practices
- Accessible via `browseVignettes()`

### Scripts (scripts/)
- **Analysis workflows** specific to your use case
- Not exported as functions
- Can use package functions
- Example: Port profiles, regular reports

### Examples (examples/)
- **Demonstration scripts** for external users
- Show common use patterns
- Copy-paste ready code
- Starting points for customization

## Benefits of This Structure

1. **Clear separation** between reusable code (R/) and specific analyses (scripts/)
2. **Professional documentation** via vignettes
3. **Quality assurance** via tests
4. **Easy distribution** - others can install just the package
5. **Flexible usage** - complete pipeline or individual functions
6. **Maintainable** - clear organization aids future development
