<#
.SYNOPSIS
    PSScriptAnalyzer custom rule to enforce Set-StrictMode -Version 3.0 directive.

.DESCRIPTION
  This custom rule ensures that PowerShell scripts include the required
  Set-StrictMode -Version 3.0 directive at the top level to enforce strict
  PowerShell syntax and variable checking, as specified in ADR PowerShell coding guidelines.

  Rule Name: PSCustomRule_StrictModeVersion
  Scope: Root script block only (ignores nested function/script blocks)

  Detection Strategy:
  1. AST Analysis: Scans for top-level Set-StrictMode commands with version 3.x
  2. Token Fallback: Uses token-based parsing for edge cases where AST might miss complex formatting
  3. Diagnostic Emission: Returns Warning-level diagnostic if directive is missing

  Accepted Patterns:
  - Set-StrictMode -Version 3.0
  - Set-StrictMode -Version 3
  - Set-StrictMode 3.0 (positional parameter)
  - Set-StrictMode 3 (positional parameter)
  - Case-insensitive matching

  Rejected Patterns:
  - Any other version (1.0, 2.0, Latest)
  - Missing directive entirely
  - Directive only inside functions (must be at script root)

.PARAMETER ScriptBlockAst
  The abstract syntax tree of the script block being analyzed.

.PARAMETER Options
  Analysis options passed from PSScriptAnalyzer.

.PARAMETER Path
  The file path of the script being analyzed (used for token fallback).

.EXAMPLE
  # This will PASS the rule
  Set-StrictMode -Version 3.0
  Write-Host "Hello World"

.EXAMPLE
  # This will FAIL the rule (missing directive)
  Write-Host "Hello World"

.EXAMPLE
  # This will FAIL the rule (directive only in function)
  function Test-Something {
      Set-StrictMode -Version 3.0
      Write-Host "Test"
  }

.EXAMPLE
  # This will FAIL the rule (wrong version)
  Set-StrictMode -Version 2.0
  Write-Host "Hello World"

.NOTES
  Version: 1.0.0
  Author: Sky-Ledger PowerShell Script Analyzer

  This rule implements organizational coding standards requiring strict mode
  version 3.0 to catch common PowerShell scripting errors and enforce
  consistent variable declaration practices.

.LINK
  https://github.com/Sky-Ledger/powershell-script-analyzer
#>
using namespace System.Management.Automation.Language
using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not ([Type]::GetType('Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord', $false))) {
  try {
    Import-Module PSScriptAnalyzer -ErrorAction SilentlyContinue
  }
  catch {
    Write-Verbose "PSScriptAnalyzer import attempt failed: $($_.Exception.Message)"
  }
}

function PSCustomRule_StrictModeVersion {
  <#
    .SYNOPSIS
      Ensures Set-StrictMode -Version 3.x is declared at script root.
    .DESCRIPTION
      Custom PSScriptAnalyzer rule that warns when a script omits a top-level
      Set-StrictMode directive for version 3 (e.g. 'Set-StrictMode -Version 3.0').
  #>
  [CmdletBinding()]
  [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
  param(
    [Parameter(Mandatory = $true)] [ScriptBlockAst] $ScriptBlockAst,
    [hashtable] $Options,
    [string] $Path
  )

  # Only evaluate the root script block; skip nested (functions, classes)
  if ($ScriptBlockAst.Parent) { return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@() }

  # Mark Options as intentionally unused (reserved for future extensibility)
  if ($PSBoundParameters.ContainsKey('Options')) { $null = $Options }

  $strictModeDirectiveFound = $false

  # --- Step 1: AST scan for top-level commands ---
  $topLevelCommands = $ScriptBlockAst.FindAll({ param($node) $node -is [CommandAst] }, $false)
  foreach ($currentCommand in $topLevelCommands) {
    $commandElements = $currentCommand.CommandElements
    if ($commandElements.Count -eq 0) { continue }
    $commandName = $commandElements[0]
    $isStrictModeCommand = ($commandName -is [StringConstantExpressionAst] -and $commandName.Value.ToLower() -eq 'set-strictmode')
    if (-not $isStrictModeCommand) { continue }
    # Collect remainder of command text (arguments)
    $commandArguments = ($commandElements | Select-Object -Skip 1 | ForEach-Object { $_.Extent.Text }) -join ' '
    if ($commandArguments -match '(?i)\b3(\.\d+)?\b') { $strictModeDirectiveFound = $true; break }
  }

  # --- Step 2: Token fallback (only if AST pass failed) ---
  if (-not $strictModeDirectiveFound -and $Path -and (Test-Path -LiteralPath $Path)) {
    try {
      $parsedTokens = $null; $parseErrors = $null
      [Parser]::ParseFile($Path, [ref]$parsedTokens, [ref]$parseErrors) | Out-Null
      for ($tokenIndex = 0; $tokenIndex -lt $parsedTokens.Length; $tokenIndex++) {
        $currentToken = $parsedTokens[$tokenIndex]
        if ($currentToken.Kind -in 'Comment', 'NewLine', 'LineContinuation') { continue }
        if ($currentToken.Text -ieq 'Set-StrictMode') {
          $lookAheadEndIndex = [Math]::Min($tokenIndex + 6, $parsedTokens.Length - 1)
          $lookAheadTokens = $parsedTokens[($tokenIndex + 1)..$lookAheadEndIndex]
          $lookAheadCommandText = ($lookAheadTokens | ForEach-Object { $_.Text }) -join ' '
          if ($lookAheadCommandText -match '(?i)\b3(\.\d+)?\b') { $strictModeDirectiveFound = $true; break }
        }
      }
    }
    catch {
      Write-Verbose "Token parse fallback failed: $($_.Exception.Message)"
    }
  }

  # --- Step 3: Emit diagnostic if still not found ---
  if (-not $strictModeDirectiveFound) {
    $diagnostic = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]::new(
      'Missing Set-StrictMode -Version 3.0 directive at script top (adr guideline).',
      $ScriptBlockAst.Extent,
      'PSCustomRule_StrictModeVersion',
      'Warning',
      $Path,
      $null
    )
    return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@(, $diagnostic)
  }
  return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@()
}
