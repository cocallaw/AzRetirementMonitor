function Get-AzRetirementMetadata {
<#
.SYNOPSIS
Gets Azure Advisor recommendation metadata
#>
    [CmdletBinding()]
    param()

    if (-not $script:AccessToken) {
        throw "Not authenticated. Run Connect-AzRetirementMonitor first."
    }

    $headers = @{
        Authorization  = "Bearer $script:AccessToken"
        "Content-Type" = "application/json"
    }

    $uri = "https://management.azure.com/providers/Microsoft.Advisor/metadata?api-version=$script:ApiVersion"

    Invoke-AzPagedRequest -Uri $uri -Headers $headers |
        ForEach-Object {
            [PSCustomObject]@{
                Name                = $_.name
                Id                  = $_.id
                Type                = $_.type
                DisplayName         = $_.properties.displayName
                DependsOn           = $_.properties.dependsOn
                ApplicableScenarios = ($_.properties.applicableScenarios -join ", ")
            }
        }
}