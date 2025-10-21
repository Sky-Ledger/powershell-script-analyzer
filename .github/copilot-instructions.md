# Project Overview

# Sky Ledger PowerShell Script Analyzer

This repository provides custom PSScriptAnalyzer rules and configuration to enforce PowerShell coding standards across Sky Ledger projects. It includes custom rules for error handling, strict mode enforcement, and comprehensive testing infrastructure with GitHub Actions CI/CD.

## Purpose

Ensures consistent PowerShell code quality and adherence to Sky Ledger's Architecture Decision Records (ADR) for PowerShell development through automated static analysis and custom rule validation.

## Folder Structure

- `/rules/`: Custom PSScriptAnalyzer rules implementation
- `/tests/`: Comprehensive Pester test suite for all custom rules
- `/.github/workflows/`: GitHub Actions CI/CD pipeline
  - `powershell-quality-check.yml`: Automated testing and validation workflow
- `/PSScriptAnalyzer.Settings.psd1`: Central configuration file for PSScriptAnalyzer
- `/Invoke-PSScriptAnalyzer.ps1`: Convenience wrapper script for analysis
- `/Test-WorkflowCompatibility.ps1`: Local development validation script
- `/README.md`: Comprehensive documentation
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

### Quality Gates
- **Pester Tests**: All custom rule tests must pass
- **Self-Analysis**: Repository analyzes itself with custom rules
- **Cross-Platform**: Testing on both Ubuntu (PowerShell Core) and Windows (Windows PowerShell)
- **Module Loading**: Validation of custom rule module import and export

### Pipeline Stages
1. **Environment Setup**: Install PSScriptAnalyzer and Pester modules
2. **Rule Import**: Load and validate custom rules module
3. **Test Execution**: Run comprehensive Pester test suite
4. **Static Analysis**: Analyze repository with own rules
5. **Compatibility Check**: Windows PowerShell 5.1 validation

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
1. Create rule file in `/rules/` directory with `PSCustomRule_*` function
2. Implement AST-based analysis with proper error handling
3. Add comprehensive test suite in `/tests/` directory
4. Update documentation and examples
5. Validate with `Test-WorkflowCompatibility.ps1`

### Local Testing
- Use `Invoke-PesterTests.ps1` for test execution
- Run `Invoke-PSScriptAnalyzer.ps1` for self-analysis
- Validate with `Test-WorkflowCompatibility.ps1` before commits

### CI/CD Integration
- GitHub Actions automatically validates all changes
- Pull requests require passing tests and analysis
- Branch protection enforces quality gates

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
