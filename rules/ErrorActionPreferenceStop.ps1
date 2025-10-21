<#
.SYNOPSIS
    PSScriptAnalyzer custom rule to enforce $ErrorActionPreference = 'Stop' directive.

.DESCRIPTION
    This custom rule ensures that PowerShell scripts include the required 
    $ErrorActionPreference = 'Stop' directive at the top level to enforce 
    terminating behavior on errors, as specified in ADR PowerShell coding guidelines.

    Rule Name: PSCustomRule_ErrorActionPreferenceStop
    Scope: Root script block only (ignores nested function/script blocks)
    
    Detection Strategy:
    1. AST Analysis: Scans for top-level assignment statements to $ErrorActionPreferenceStop variable
    2. Token Fallback: Uses token-based parsing for edge cases where AST might miss complex formatting
    3. Diagnostic Emission: Returns Warning-level diagnostic if directive is missing
    
    Accepted Patterns:
    - $ErrorActionPreference = 'Stop'
    - $ErrorActionPreference = "Stop" 
    - $ErrorActionPreference='Stop' (no spaces)
    - Case-insensitive matching (stop, STOP, Stop)
    
    Rejected Patterns:
    - Any other value (Continue, SilentlyContinue, Inquire)
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
    $ErrorActionPreference = 'Stop'
    Write-Host "Hello World"

.EXAMPLE  
    # This will FAIL the rule (missing directive)
    Write-Host "Hello World"

.EXAMPLE
    # This will FAIL the rule (directive only in function)
    function Test-Something {
        $ErrorActionPreference = 'Stop'
        Write-Host "Test"
    }

.NOTES
    Version: 1.0.0
    Author: Sky-Ledger PowerShell Script Analyzer
    
    This rule implements organizational coding standards requiring explicit
    error handling behavior in all PowerShell scripts.

.LINK
    https://github.com/Sky-Ledger/powershell-script-analyzer
#>
using namespace System.Management.Automation.Language
using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not ([Type]::GetType('Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord', $false))) {
  try { Import-Module PSScriptAnalyzer -ErrorAction SilentlyContinue } catch {}
}

function PSCustomRule_ErrorActionPreferenceStop {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)] [ScriptBlockAst] $ScriptBlockAst,
    [hashtable] $Options,
    [string] $Path
  )

  # Only evaluate the root script block; skip nested (functions, classes)
  if ($ScriptBlockAst.Parent) { return @() }

  $errorActionPreferenceFound = $false

  # --- Step 1: AST scan for assignment statements (exclude those inside functions) ---
  $assignments = $ScriptBlockAst.FindAll({ param($n) $n -is [AssignmentStatementAst] }, $true)
  foreach ($assignmentStatement in $assignments) {
    # Determine if inside a function
    $ancestorNode = $assignmentStatement.Parent; $isInsideFunction = $false
    while ($ancestorNode) {
      if ($ancestorNode -is [FunctionDefinitionAst]) { $isInsideFunction = $true; break }
      if ($ancestorNode -eq $ScriptBlockAst) { break }
      $ancestorNode = $ancestorNode.Parent
    }
    if ($isInsideFunction) { continue }
    if ($assignmentStatement.Left -is [VariableExpressionAst] -and $assignmentStatement.Left.VariablePath.UserPath -ieq 'ErrorActionPreference') {
      $rightSideValue = $assignmentStatement.Right.Extent.Text.Trim()
      if ((($rightSideValue.StartsWith('"')) -and $rightSideValue.EndsWith('"')) -or (($rightSideValue.StartsWith("'")) -and $rightSideValue.EndsWith("'"))) {
        $rightSideValue = $rightSideValue.Substring(1, $rightSideValue.Length - 2)
      }
      if ($rightSideValue -ieq 'Stop') { $errorActionPreferenceFound = $true; break }
    }
  }

  # --- Step 2: Token fallback if not found ---
  if (-not $errorActionPreferenceFound -and $Path -and (Test-Path -LiteralPath $Path)) {
    try {
      $parsedTokens = $null; $parseErrors = $null
      [Parser]::ParseFile($Path, [ref]$parsedTokens, [ref]$parseErrors) | Out-Null
      for ($i=0; $i -lt $parsedTokens.Length; $i++) {
        $currentToken = $parsedTokens[$i]
        if ($currentToken.Kind -in 'Comment','NewLine','LineContinuation') { continue }
        if ($currentToken.Text -eq '$ErrorActionPreference') {
          $searchLimit = [Math]::Min($i+8, $parsedTokens.Length-1)
          $foundEqualsOperator = $false
          for ($nextTokenIndex=$i+1; $nextTokenIndex -le $searchLimit; $nextTokenIndex++) {
            $nextToken = $parsedTokens[$nextTokenIndex]
            if ($nextToken.Kind -in 'Comment','NewLine','LineContinuation') { continue }
            if (-not $foundEqualsOperator) {
              if ($nextToken.Text -eq '=') { $foundEqualsOperator = $true; continue }
              else { break } # unexpected token before '='
            } else {
              # value token
              $tokenValue = $nextToken.Text.Trim()
              if ((($tokenValue.StartsWith('"')) -and $tokenValue.EndsWith('"')) -or (($tokenValue.StartsWith("'")) -and $tokenValue.EndsWith("'"))) {
                $tokenValue = $tokenValue.Substring(1, $tokenValue.Length - 2)
              }
              if ($tokenValue -ieq 'Stop') { $errorActionPreferenceFound = $true }
              break
            }
          }
        }
        if ($errorActionPreferenceFound) { break }
      }
    } catch { }
  }

  if (-not $errorActionPreferenceFound) {
    $diagnostic = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]::new(
      'Missing ''$ErrorActionPreference = "Stop"'' directive at top of script (adr-powershell-coding-guidelines).',
      $ScriptBlockAst.Extent,
      'PSCustomRule_ErrorActionPreferenceStop',
      'Warning',
      $Path,
      $null
    )
    return ,$diagnostic
  }
  return @()
}