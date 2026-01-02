function Get-AzRetirementRecommendations {
<#
.SYNOPSIS
Gets Azure service retirement recommendations
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$SubscriptionId,

        [ValidateSet("HighAvailability", "Security", "Performance", "Cost", "OperationalExcellence")]
        [string]$Category,

        [ValidateSet("High", "Medium", "Low")]
        [string]$ImpactLevel
    )

    begin {
        if (-not $script:AccessToken) {
            throw "Not authenticated. Run Connect-AzRetirementMonitor first."
        }

        $headers = @{
            Authorization  = "Bearer $script:AccessToken"
            "Content-Type" = "application/json"
        }

        $allRecommendations = @()
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

            if ($Category) {
                $uri += "&`$filter=Category eq '$Category'"
            }

            try {
                $recommendations = Invoke-AzPagedRequest `
                    -Uri $uri `
                    -Headers $headers

                foreach ($rec in $recommendations) {

                    if ($ImpactLevel -and $rec.properties.impact -ne $ImpactLevel) {
                        continue
                    }

                    $isRetirement =
                        $rec.properties.shortDescription.problem -match
                        'retire|deprecat|end of life|eol|sunset'

                    $allRecommendations += [PSCustomObject]@{
                        SubscriptionId   = $subId
                        ResourceId       = $rec.properties.resourceMetadata.resourceId
                        ResourceName     = ($rec.properties.resourceMetadata.resourceId -split "/")[-1]
                        Category         = $rec.properties.category
                        Impact           = $rec.properties.impact
                        Problem          = $rec.properties.shortDescription.problem
                        Solution         = $rec.properties.shortDescription.solution
                        Description      = $rec.properties.extendedProperties.displayName
                        LastUpdated      = $rec.properties.lastUpdated
                        IsRetirement     = $isRetirement
                        RecommendationId = $rec.name
                        LearnMoreLink    = $rec.properties.learnMoreLink
                    }
                }
            }
            catch {
                Write-Warning "Failed to query subscription $($subId) $_"
            }
        }
    }

    end {
        return $allRecommendations
    }
}