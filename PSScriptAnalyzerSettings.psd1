@{
    Severity = @('Error', 'Warning')

    IncludeRules = @(
        'PSAvoidDefaultValueSwitchParameter'
        'PSAvoidGlobalVars'
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingPlainTextForPassword'
        'PSAvoidUsingPositionalParameters'
        'PSAvoidUsingWriteHost'
        'PSMisleadingBacktick'
        'PSMissingModuleManifestField'
        'PSProvideCommentHelp'
        'PSReservedCmdletChar'
        'PSReservedParams'
        'PSShouldProcess'
        'PSUseApprovedVerbs'
        'PSUseConsistentIndentation'
        'PSUseConsistentWhitespace'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUseProcessBlockForPipelineCommand'
        'PSUseSingularNouns'
    )

    ExcludeRules = @(
        # Connect-/Disconnect- functions use Write-Host intentionally for user-facing status
        # Suppress globally; individual functions use SuppressMessageAttribute where needed
    )

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            Kind            = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator                  = $true
        }
        PSUseCompatibleSyntax = @{
            Enable            = $true
            TargetVersions    = @('5.1', '7.0')
        }
    }
}
