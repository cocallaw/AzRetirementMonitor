function Get-AzRetirementRecommendation {
<#
.SYNOPSIS
Gets Azure service retirement recommendations for HighAvailability category and ServiceUpgradeAndRetirement subcategory
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$SubscriptionId
    )

    begin {
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

        $allRecommendations = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if (-not $SubscriptionId) {
            $subsUri = "https://management.azure.com/subscriptions?api-version=2020-01-01"
            $subs = Invoke-AzPagedRequest -Uri $subsUri -Headers $headers
            $SubscriptionId = $subs.subscriptionId
        }

        foreach ($subId in $SubscriptionId) {
            Write-Verbose "Querying subscription: $subId"

            $uri = "https://management.azure.com/subscriptions/$subId/providers/Microsoft.Advisor/recommendations?api-version=$script:ApiVersion"

            # Filter for HighAvailability category and ServiceUpgradeAndRetirement subcategory only
            $filter = "Category eq 'HighAvailability' and SubCategory eq 'ServiceUpgradeAndRetirement'"
            $uri += "&`$filter=$filter"

            try {
                $recommendations = Invoke-AzPagedRequest `
                    -Uri $uri `
                    -Headers $headers

                foreach ($rec in $recommendations) {
                    $isRetirement =
                        $rec.properties.shortDescription.problem -match
                        'retire|deprecat|end of life|eol|sunset'

                    # Extract ResourceType from ResourceId
                    $resourceId = $rec.properties.resourceMetadata.resourceId
                    $resourceType = if ($resourceId) {
                        # Extract provider/type from resourceId
                        # Example: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{name}
                        if ($resourceId -match '/providers/([^/]+/[^/]+)(?:/|$)') {
                            $matches[1]
                        } else {
                            "N/A"
                        }
                    } else {
                        "N/A"
                    }

                    # Extract Resource Group from ResourceId
                    $resourceGroup = if ($resourceId) {
                        # Extract resource group name from resourceId
                        # Example: /subscriptions/{sub}/resourceGroups/{rg}/providers/...
                        if ($resourceId -match '/resourceGroups/([^/]+)') {
                            $matches[1]
                        } else {
                            "N/A"
                        }
                    } else {
                        "N/A"
                    }

                    # Build Azure Resource portal link
                    $resourceLink = if ($resourceId) {
                        "https://portal.azure.com/#resource$resourceId"
                    } else {
                        $null
                    }

                    $allRecommendations.Add([PSCustomObject]@{
                        SubscriptionId   = $subId
                        ResourceId       = $resourceId
                        ResourceName     = ($resourceId -split "/")[-1]
                        ResourceType     = $resourceType
                        ResourceGroup    = $resourceGroup
                        Category         = $rec.properties.category
                        Impact           = $rec.properties.impact
                        Problem          = $rec.properties.shortDescription.problem
                        Solution         = $rec.properties.shortDescription.solution
                        Description      = $rec.properties.extendedProperties.displayName
                        LastUpdated      = $rec.properties.lastUpdated
                        IsRetirement     = $isRetirement
                        RecommendationId = $rec.name
                        LearnMoreLink    = $rec.properties.learnMoreLink
                        ResourceLink     = $resourceLink
                    })
                }
            }
            catch {
                Write-Warning "Failed to query subscription $($subId) $_"
            }
        }
    }

    end {
        return $allRecommendations.ToArray()
    }
}