# Project Overview

# Sky Ledger PowerShell Script Analyzer

This repository provides custom PSScriptAnalyzer rules and configuration to enforce PowerShell coding standards across Sky Ledger projects. It includes custom rules for error handling, strict mode enforcement, and comprehensive testing infrastructure with GitHub Actions CI/CD.

## Purpose

Ensures consistent PowerShell code quality and adherence to Sky Ledger's Architecture Decision Records (ADR) for PowerShell development through automated static analysis and custom rule validation.

## Folder Structure

- `/rules/`: Custom PSScriptAnalyzer rules implementation
  - `00-SkyLedger.Rules.psm1`: Main rules module containing custom PSCustomRule functions
  - `ErrorActionPreferenceStop.ps1`: Rule enforcing proper error handling configuration
  - `StrictModeVersion.ps1`: Rule enforcing strict mode usage
- `/tests/`: Comprehensive Pester test suite for all custom rules
  - `Invoke-PesterTests.ps1`: Test runner script with professional configuration
  - Individual test files for each custom rule with AAA pattern documentation
- `/scripts/`: Development and maintenance scripts
  - `Test-WorkflowCompatibility.ps1`: Local development validation script for CI/CD compatibility
- `/.github/`: GitHub integration and configuration
  - `copilot-instructions.md`: Development context and project guidelines for AI assistance
  - `/workflows/`: GitHub Actions CI/CD pipeline
    - `powershell-quality-check.yml`: Automated testing and validation workflow with inline scripts
- `/PSScriptAnalyzer.Settings.psd1`: Central configuration file for PSScriptAnalyzer
- `/Invoke-PSScriptAnalyzer.ps1`: Convenience wrapper script for repository analysis
- `/README.md`: Comprehensive project documentation with usage examples and troubleshooting
- `/LICENSE`: MIT License

## Libraries and Frameworks

- **PSScriptAnalyzer**: Microsoft's PowerShell static analysis tool
- **Pester v5+**: PowerShell testing framework for unit and integration tests
- **PowerShell 5.1+ / PowerShell Core 7.0+**: Cross-platform PowerShell support
- **GitHub Actions**: CI/CD pipeline for automated testing
- **AST (Abstract Syntax Tree)**: PowerShell code parsing and analysis
- **PowerShell Language Server**: VS Code integration and IntelliSense

## Custom Rules Architecture

### Rule Implementation Pattern
- Each rule is a standalone PowerShell function named `PSCustomRule_*`
- Uses AST parsing for accurate code analysis
- Implements token fallback for edge cases
- Returns `DiagnosticRecord` objects for PSScriptAnalyzer integration
- Follows consistent error handling and logging patterns

### Rule Categories
1. **Error Handling Rules**: Enforce proper error management (`ErrorActionPreferenceStop`)
2. **Code Quality Rules**: Enforce strict mode and best practices (`StrictModeVersion`)
3. **Extensible Framework**: Easy addition of new rules following established patterns

## Coding Standards

### PowerShell Best Practices
- **Strict Mode**: All scripts must use `Set-StrictMode -Version 3.0`
- **Error Handling**: All scripts must set `$ErrorActionPreference = 'Stop'`
- **Comment-Based Help**: Complete `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE` documentation
- **Parameter Validation**: Proper `[Parameter()]` attributes and type constraints
- **Consistent Formatting**: Following PSScriptAnalyzer recommendations

### Rule Development Standards
- Each custom rule must have comprehensive test coverage
- Rules should handle edge cases and provide helpful diagnostic messages
- AST-based implementation preferred over regex parsing
- Token fallback for cases where AST parsing is insufficient
- Proper namespace usage for type resolution

### Testing Requirements
- **Unit Tests**: Each rule must have positive and negative test cases
- **Edge Case Testing**: Test unusual formatting, spacing, and syntax variations
- **Integration Testing**: Validate rules work within PSScriptAnalyzer framework
- **CI/CD Validation**: All tests must pass in GitHub Actions pipeline

## GitHub Actions Workflow

### Architecture
The CI/CD pipeline uses **inline PowerShell scripts** within the GitHub Actions workflow file for maximum transparency and maintainability. Each step contains comprehensive PowerShell code with proper error handling, colored output, and detailed logging.

### Quality Gates
- **Pester Tests**: All custom rule tests must pass with detailed test result reporting
- **Self-Analysis**: Repository analyzes itself with custom rules using PSScriptAnalyzer
- **Cross-Platform**: Testing on both Ubuntu (PowerShell Core 7.x) and Windows (Windows PowerShell 5.1)
- **Module Loading**: Validation of custom rule module import and export with function discovery
- **Syntax Validation**: Windows PowerShell compatibility with AST-based syntax parsing

### Pipeline Stages
1. **Environment Setup**: PowerShell version detection and environment information display
2. **Module Installation**: Install PSScriptAnalyzer and Pester v5+ with verification and version reporting
3. **Rule Import**: Load and validate custom rules module with automatic function discovery
4. **Test Execution**: Run comprehensive Pester test suite with CI-optimized output formatting
5. **Static Analysis**: Analyze entire repository with custom and built-in rules, including informational messages
6. **Quality Summary**: Consolidated results with color-coded success/failure status
7. **Compatibility Check**: Windows PowerShell 5.1 validation with syntax parsing and basic functionality tests

### Workflow Implementation Details
- **Inline Scripts**: All PowerShell logic embedded directly in workflow YAML for transparency
- **Error Propagation**: Proper exit code handling to fail CI/CD on any quality issues  
- **Verbose Output**: Comprehensive logging with color-coded messages for easy debugging
- **Module Verification**: Dynamic verification of installed modules and available custom rules
- **Cross-Platform Support**: Separate jobs for Ubuntu (PowerShell Core) and Windows (Windows PowerShell)

## Configuration Management

### PSScriptAnalyzer.Settings.psd1
- **Severity Levels**: Error, Warning, Information
- **Custom Rule Path**: Points to rules module
- **Built-in Rules**: Comprehensive set of Microsoft's standard rules
- **Rule Exclusions**: Minimal exclusions to maintain high standards

### Rule Discoverability
- Dynamic rule loading via module pattern
- Automatic function export based on naming convention
- Supports adding new rules without configuration changes
- Idempotent module import for development workflows

## Development Workflow

### Adding New Rules
1. Create rule file in `/rules/` directory with `PSCustomRule_*` function following established patterns
2. Implement AST-based analysis with proper error handling and token fallback strategies  
3. Add the rule function to `rules/00-SkyLedger.Rules.psm1` module exports
4. Create comprehensive test suite in `/tests/` directory using AAA (Arrange, Act, Assert) pattern
5. Update documentation with clear examples of compliant and non-compliant code
6. Validate with `scripts/Test-WorkflowCompatibility.ps1` to ensure CI/CD compatibility
7. Test locally with `tests/Invoke-PesterTests.ps1` and `Invoke-PSScriptAnalyzer.ps1`

### Local Testing
- Use `tests/Invoke-PesterTests.ps1` for comprehensive test execution with detailed output
- Run `Invoke-PSScriptAnalyzer.ps1` for repository self-analysis with custom rules
- Validate with `scripts/Test-WorkflowCompatibility.ps1` before commits to ensure CI/CD compatibility
- Test individual rules during development with targeted Pester test files

### CI/CD Integration
- **Automated Validation**: GitHub Actions automatically validates all PowerShell file changes
- **Branch Protection**: Pull requests require passing tests and analysis before merge
- **Quality Gates**: Both Pester tests and PSScriptAnalyzer must pass without errors
- **Cross-Platform Testing**: Validates compatibility on both Linux (PowerShell Core) and Windows (Windows PowerShell)
- **Inline Script Architecture**: All workflow logic embedded in YAML for maximum transparency and easier maintenance
- **Comprehensive Logging**: Detailed output with color-coded status messages for effective debugging

## Documentation Standards

### Rule Documentation
- Complete comment-based help for all functions
- Clear purpose and scope definition in rule headers
- Strategy explanation for complex analysis logic
- Examples of compliant and non-compliant code

### Test Documentation
- Descriptive test names explaining validation scenario
- Clear test case organization by rule and scenario type
- Comprehensive coverage documentation

### README Requirements
- **Comprehensive Coverage**: Complete feature and usage documentation
- **Professional Formatting**: Rich markdown with emojis, badges, and code examples
- **Practical Examples**: Real-world usage scenarios and command references
- **Troubleshooting**: Common issues and solutions
- **Contributing Guidelines**: Clear development and contribution workflow
