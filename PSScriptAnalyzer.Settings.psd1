@{
  # 1. Include all built-in rules, even if we use IncludeRules below
  IncludeDefaultRules = $true

  # 2. Specify the path(s) to custom rules (if any)
  CustomRulePath      = '.\rules\00-Custom.Rules.psm1'       # Renamed custom rules module file

  # 3. Include custom rules (pattern or names), in addition to defaults
  IncludeRules        = @(
    '*'   # enable all custom rules with this naming pattern
    # (No need to list built-in rules here since IncludeDefaultRules is true)
  )

  # 4. Configure specific rules (enable disabled ones and set parameters)
  Rules               = @{

    # Enable rules that are off by default, with recommended settings:
    PSAlignAssignmentStatement                = @{
      Enable         = $true
      CheckHashtable = $true      # align '=' in hash table entries as well
    }
    PSAvoidExclaimOperator                    = @{
      Enable = $true       # flag '!' usage (prefer -not)
    }
    PSAvoidLongLines                          = @{
      Enable            = $true
      MaximumLineLength = 140     # max 140 chars per line[2](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/avoidlonglines?view=ps-modules)
    }
    PSAvoidSemicolonsAsLineTerminators        = @{
      Enable = $true       # flag unnecessary semicolons at EOL
    }
    PSAvoidUsingDoubleQuotesForConstantString = @{
      Enable = $true       # prefer single quotes for literal strings
    }
    PSPlaceOpenBrace                          = @{
      Enable             = $true
      OnSameLine         = $true       # e.g. "if (...) {"
      NewLineAfter       = $true       # content starts on a new line
      IgnoreOneLineBlock = $true  # ignore braces for one-line constructs
    }
    PSPlaceCloseBrace                         = @{
      Enable             = $true
      NoEmptyLineBefore  = $true   # no blank line before closing brace
      NewLineAfter       = $true       # ensure newline (no code on same line as })
      IgnoreOneLineBlock = $true  # ignore one-line constructs
    }
    # PSUseCompatibleCommands = @{
    #     Enable        = $true
    #     TargetProfiles = @(
    #         # Check compatibility with Windows PowerShell 5.1 on Windows Server 2019:
    #         'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
    #         # ...and with PowerShell 7.0 on Ubuntu 18.04:
    #         'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
    #     )
    #     # (Add or change profiles to those relevant for your environment)
    # }
    PSUseCompatibleSyntax                     = @{
      Enable         = $true
      TargetVersions = @('5.1', '7.0')  # ensure syntax works in PS 5.1 and 7.0[10](https://argonsys.com/microsoft-cloud/library/using-psscriptanalyzer-to-check-powershell-version-compatibility/)
    }
    # PSUseCompatibleTypes = @{
    #     Enable         = $true
    #     TargetProfiles = @(
    #         'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
    #         'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
    #     )
    # }
    PSUseConsistentIndentation                = @{
      Enable              = $false   # incompatible with powershell formatter in visual studio code [11](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentindentation?view=ps-modules)
      # IndentationSize     = 2        # 2 spaces per indent level
      # PipelineIndentation = 'IncreaseIndentationForFirstPipeline'  # common style[11](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentindentation?view=ps-modules)
      # Kind                = 'space'  # use spaces (not tabs) for indentation[11](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentindentation?view=ps-modules)
    }
    PSUseConsistentWhitespace                 = @{
      Enable                                  = $true
      CheckInnerBrace                         = $true   # space after { and before }[12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
      CheckOpenBrace                          = $true   # space between keyword and {[12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
      CheckOpenParen                          = $true   # space between keyword and ([12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
      CheckOperator                           = $true   # spaces around operators[12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
      CheckSeparator                          = $true   # space after commas/semicolons[12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
      CheckPipe                               = $true   # spaces around '|' pipe[12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
      CheckPipeForRedundantWhitespace         = $true   # no multiple spaces around '|'[12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
      CheckParameter                          = $true   # no extra spaces in param assignments[12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
      IgnoreAssignmentOperatorInsideHashTable = $true  # allow alignment in hashtables[12](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/useconsistentwhitespace?view=ps-modules)
    }
    PSUseCorrectCasing                        = @{
      Enable = $true   # enforce consistent casing (cmdlet & parameter names)
    }

    # Adjust settings for default-enabled rules to tighten best practices:
    PSAvoidUsingCmdletAliases                 = @{
      AllowList = @()     # disallow all aliases in scripts (no exceptions)[4](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/avoidusingcmdletaliases?view=ps-modules)
    }
    PSProvideCommentHelp                      = @{
      ExportedOnly            = $false  # demand help for all functions, not just exported/public[7](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/providecommenthelp?view=ps-modules)
      BlockComment            = $true   # use multi-line comment style for help (<# ... #>)
      VSCodeSnippetCorrection = $true  # enable snippet-style help suggestions
      Placement               = 'before'  # place comment help before function (default)[7](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/providecommenthelp?view=ps-modules)
    }
    PSUseSingularNouns                        = @{
      NounAllowList = @('Data', 'Windows')  # allowed plural terms as exceptions
    }

    # (No need to list every default rule here – those not mentioned will use their defaults)
  }
}