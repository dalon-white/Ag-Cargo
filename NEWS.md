# Changelog

All notable changes to the AgCargoPestRisk project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-06

### Added
- Initial package structure with modular functions
- Database connection and query functions (`database_functions.R`)
- Data processing and cleaning functions (`data_processing.R`)
- Risk assessment and taxonomy matching functions (`risk_assessment.R`)
- Analysis and summarization functions (`analysis_functions.R`)
- Complete pipeline function for end-to-end workflow (`pipeline.R`)
- Support for OPEP, FNW, and HLI pest impact assessments
- Modular RMarkdown workflows (Module A, B, C)
- Example usage scripts for external users
- Comprehensive README and documentation

### Features
- Flexible pest risk scoring based on quarantine status and impact assessments
- Taxonomy matching across multiple pest databases
- Commodity-origin pathway assessment
- Port-level risk summarization
- Export to CSV and RDS formats
- Support for both complete pipeline and modular usage

## [Unreleased]

### Planned
- Unit tests for all core functions
- Vignettes for common use cases
- Database-hosted pest impact data integration
- Visualization templates for port reports
- Performance optimization for large datasets
- Additional export formats (Excel, JSON)

---

## Version Guidelines

- **Major (x.0.0)**: Breaking API changes
- **Minor (0.x.0)**: New features, backwards compatible
- **Patch (0.0.x)**: Bug fixes, documentation updates
