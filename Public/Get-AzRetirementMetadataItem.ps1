function Get-AzRetirementMetadataItem {
<#
.SYNOPSIS
Gets Azure Advisor recommendation metadata
.DESCRIPTION
Note: This function only works with the -UseAPI mode as Az.Advisor module does not 
expose metadata retrieval cmdlets. You must run Connect-AzRetirementMonitor -UsingAPI first.
.EXAMPLE
Get-AzRetirementMetadataItem
Gets all retirement-related metadata items from Azure Advisor.
.OUTPUTS
PSCustomObject
.LINK
https://learn.microsoft.com/rest/api/advisor/metadata
#>
    [CmdletBinding()]
    param()

    if (-not $script:AccessTokenSecureString) {
        throw "Not authenticated. Run Connect-AzRetirementMonitor -UsingAPI first. Note: This function requires API access as Az.Advisor module does not expose metadata cmdlets."
    }

    if (-not (Test-AzRetirementMonitorToken)) {
        throw "Access token has expired. Run Connect-AzRetirementMonitor -UsingAPI again."
    }

    $credential = New-Object System.Management.Automation.PSCredential("token", $script:AccessTokenSecureString)
    $accessToken = $credential.GetNetworkCredential().Password
    if ([string]::IsNullOrEmpty($accessToken)) {
        throw "Stored access token is empty."
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