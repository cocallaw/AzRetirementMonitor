function Get-AzRetirementMetadataItem {
<#
.SYNOPSIS
Gets Azure Advisor recommendation metadata
#>
    [CmdletBinding()]
    param()

    if (-not $script:AccessToken) {
        throw "Not authenticated. Run Connect-AzRetirementMonitor first."
    }

    if (-not (Test-AzRetirementMonitorToken)) {
        throw "Access token has expired. Run Connect-AzRetirementMonitor again."
    }

    $headers = @{
        Authorization  = "Bearer $script:AccessToken"
        "Content-Type" = "application/json"
    }

    # Filter for HighAvailability category and ServiceUpgradeAndRetirement subcategory
    $filter = "recommendationCategory eq 'HighAvailability' and recommendationSubCategory eq 'ServiceUpgradeAndRetirement'"
    $uri = "https://management.azure.com/providers/Microsoft.Advisor/metadata?api-version=$script:ApiVersion&`$filter=$filter"

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