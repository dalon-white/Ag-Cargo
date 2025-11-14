# Quick Start Checklist

Use this checklist to get your package up and running.

## ☐ Phase 1: Verify Setup (5 minutes)

```r
# Open R in your project directory
setwd("C:/Users/Dalon.White/OneDrive - USDA/Desktop/Projects/Ag-Cargo")

# Check that you have required packages
install.packages(c("devtools", "testthat", "roxygen2", "knitr", "rmarkdown"))
```

## ☐ Phase 2: Build Package (10 minutes)

```r
library(devtools)

# Step 1: Generate documentation from roxygen comments
document()
# ✅ Should create .Rd files in man/ directory
# ✅ Should update NAMESPACE

# Step 2: Run tests
test()
# ✅ All tests should pass (or some may need adjustment for your data)

# Step 3: Check package
check()
# ⚠️ May show warnings - that's ok for now
# ❌ Should have NO errors
```

## ☐ Phase 3: Install Locally (2 minutes)

```r
# Install the package
install()

# Verify it works
library(AgCargoPestRisk)

# Check available functions
ls("package:AgCargoPestRisk")

# Get help
?run_pest_risk_pipeline
```

## ☐ Phase 4: Test Basic Functionality (15 minutes)

```r
# Try a small test run
test_results <- run_pest_risk_pipeline(
  begin_date = "2024-01-01",
  end_date = "2024-01-31",  # Just one month to test
  opep_directory = "Inputs/Data/OPEP",
  fnw_directory = "Inputs/Data/FNW",
  hli_directory = "Inputs/Data/High and low impact pests",
  output_dir = "outputs/test_run",
  export_results = TRUE
)

# Check outputs
list.files("outputs/test_run")

# View results
head(test_results$pathway_assessment)
```

## ☐ Phase 5: Compare with Original (30 minutes)

Run your original script side-by-side with the new version:

```r
# Original
source("pest risk lists.Rmd")  # Your original workflow
original_results <- pathway.assessment

# New version
library(AgCargoPestRisk)
new_results <- run_pest_risk_pipeline(...)

# Compare
all.equal(original_results, new_results$pathway_assessment)
```

## ☐ Phase 6: Try Modular Approach (15 minutes)

```r
# Test using individual functions
conn <- connect_db()
diagnostic_data <- get_diagnostic_results(conn, "2024-01-01", "2024-01-31")
DBI::dbDisconnect(conn)

opep_data <- load_opep_data("Inputs/Data/OPEP")
diagnostic_data <- integrate_opep_impacts(diagnostic_data, opep_data)

# Verify it works
summary(diagnostic_data)
```

## ☐ Phase 7: Review Documentation (20 minutes)

```r
# Read the vignettes
browseVignettes("AgCargoPestRisk")

# Or manually
rmarkdown::render("vignettes/getting-started.Rmd")
# Opens HTML in browser

# Check function documentation
?connect_db
?integrate_opep_impacts
?summarize_commodity_pest_risk
```

## ☐ Phase 8: Try Examples (30 minutes)

```r
# Run the port-specific analysis example
source("examples/port_specific_analysis.R")

# Modify it for your favorite port
TARGET_PORT <- "Your Port Name, ST"
# Run again
```

## ☐ Phase 9: Share with Colleague (Optional)

Have a colleague try to:
1. Install the package
2. Run the complete pipeline
3. Give feedback on usability

## ☐ Phase 10: Plan Next Features

Based on your testing, decide:
- [ ] What additional functions are needed?
- [ ] What documentation should be improved?
- [ ] What examples would be most helpful?
- [ ] What tests need to be added?

---

## Troubleshooting

### Issue: Tests fail
**Solution**: Some tests may need adjustment for your specific data structure. Comment out failing tests initially and fix them later.

### Issue: Package won't build
**Solution**: 
```r
# Check for syntax errors
devtools::load_all()

# Check DESCRIPTION file is valid
```

### Issue: Functions not found
**Solution**: 
```r
# Make sure NAMESPACE is up to date
devtools::document()

# Reinstall
devtools::install()
```

### Issue: Can't connect to database
**Solution**: Verify your database connection settings in `database_functions.R`

### Issue: Data files not found
**Solution**: Check paths in your function calls match your directory structure

---

## Quick Commands Reference

```r
# Development cycle
devtools::load_all()    # Load functions without installing
devtools::document()    # Update documentation
devtools::test()        # Run tests
devtools::check()       # Full package check
devtools::install()     # Install package

# Using the package
library(AgCargoPestRisk)
?function_name          # Get help
example(function_name)  # Run examples
```

---

## Success Checklist

Your setup is successful when you can:
- ✅ Run `devtools::check()` with no errors
- ✅ Load the package with `library(AgCargoPestRisk)`
- ✅ View help with `?run_pest_risk_pipeline`
- ✅ Run the complete pipeline successfully
- ✅ Access results from the pipeline
- ✅ Use individual functions independently

---

## Next Steps After Setup

Once everything is working:
1. Update `NEWS.md` with current version
2. Add more tests as you discover edge cases
3. Create additional examples for common use cases
4. Share with team for feedback
5. Plan version 0.2.0 features

---

**Estimated Total Time: 2-3 hours for complete setup and testing**
