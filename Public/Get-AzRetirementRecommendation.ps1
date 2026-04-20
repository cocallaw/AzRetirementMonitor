function Get-AzRetirementRecommendation {
<#
.SYNOPSIS
Gets Azure service retirement recommendations for HighAvailability category and ServiceUpgradeAndRetirement subcategory
.DESCRIPTION
By default, uses the Az.Advisor PowerShell module to retrieve recommendations. This provides
complete parity with Azure Advisor data. Optionally, use -UseAPI to query the REST API directly
(requires Connect-AzRetirementMonitor first).

The Az.Advisor module method requires:
- Az.Advisor module installed
- Active Azure PowerShell session (Connect-AzAccount)

The API method requires:
- Connect-AzRetirementMonitor called first
- Valid access token
.PARAMETER SubscriptionId
One or more subscription IDs to query. Defaults to all subscriptions.
.PARAMETER UseAPI
Use the Azure REST API instead of Az.Advisor PowerShell module. Requires Connect-AzRetirementMonitor first.
.EXAMPLE
Get-AzRetirementRecommendation
Gets all retirement recommendations using Az.Advisor module (default)
.EXAMPLE
Get-AzRetirementRecommendation -SubscriptionId "12345678-1234-1234-1234-123456789012"
Gets recommendations for a specific subscription using Az.Advisor module
.EXAMPLE
Get-AzRetirementRecommendation -UseAPI
Gets recommendations using the REST API method
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string[]]$SubscriptionId,

        [Parameter()]
        [switch]$UseAPI
    )

    begin {
        $allRecommendations = [System.Collections.Generic.List[object]]::new()

        if ($UseAPI) {
            # API mode - requires authentication via Connect-AzRetirementMonitor
            if (-not $script:AccessToken) {
                throw "Not authenticated. Run Connect-AzRetirementMonitor -UsingAPI first."
            }

            if (-not (Test-AzRetirementMonitorToken)) {
                throw "Access token has expired. Run Connect-AzRetirementMonitor -UsingAPI again."
            }

            $headers = @{
                Authorization  = "Bearer $script:AccessToken"
                "Content-Type" = "application/json"
            }
        }
        else {
            # PowerShell module mode (default) - requires Az.Advisor and active session
            if (-not (Test-AzAdvisorSession)) {
                throw "Az.Advisor module not available or not connected. Run Connect-AzAccount first or use -UseAPI with Connect-AzRetirementMonitor."
            }
        }
    }

    process {
        if ($UseAPI) {
            # API-based retrieval (original implementation)
            if (-not $SubscriptionId) {
                $subsUri = "https://management.azure.com/subscriptions?api-version=2020-01-01"
                $subs = Invoke-AzPagedRequest -Uri $subsUri -Headers $headers
                $SubscriptionId = $subs.subscriptionId
            }

            foreach ($subId in $SubscriptionId) {
                Write-Verbose "Querying subscription via API: $subId"

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
                    Write-Warning "Failed to query subscription $($subId): $_"
                }
            }
        }
        else {
            # PowerShell module-based retrieval (new default)
            try {
                # Get recommendations and filter by Category first (more efficient)
                $filter = "Category eq 'HighAvailability'"

                # Common filter for ServiceUpgradeAndRetirement subcategory
                $subcategoryFilter = {
                    if ($_.ExtendedProperty) {
                        $extProps = $_.ExtendedProperty | ConvertFrom-Json
                        if ($extProps.recommendationSubCategory -eq 'ServiceUpgradeAndRetirement') {
                            $_ | Add-Member -NotePropertyName ExtendedPropertyObject -NotePropertyValue $extProps -Force
                            $true
                        } else { $false }
                    }
                    else {
                        $false
                    }
                }
                
                $recommendations = if ($SubscriptionId) {
                    # Query specific subscriptions
                    # Store the current context to restore later
                    $originalContext = Get-AzContext
                    
                    foreach ($subId in $SubscriptionId) {
                        Write-Verbose "Querying subscription via Az.Advisor: $subId"
                        
                        # Set context to the specific subscription
                        try {
                            $context = Set-AzContext -SubscriptionId $subId -ErrorAction Stop
                            
                            # Verify that the context was actually set to the intended subscription
                            if (-not $context -or -not $context.Subscription -or $context.Subscription.Id -ne $subId) {
                                Write-Warning "Azure context for subscription $($subId) could not be verified. Skipping recommendation query for this subscription."
                                continue
                            }
                            
                        }
                        catch {
                            Write-Warning "Failed to set Azure context for subscription $($subId): $_"
                            continue
                        }

                        # Query Advisor recommendations for the current subscription
                        try {
                            Get-AzAdvisorRecommendation -Filter $filter | Where-Object $subcategoryFilter
                        }
                        catch {
                            Write-Warning "Failed to query Advisor recommendations for subscription $($subId): $_"
                        }
                    }
                    
                    # Restore the original context
                    if ($originalContext) {
                        try {
                            $null = Set-AzContext -Context $originalContext -ErrorAction Stop
                        }
                        catch {
                            Write-Warning "Failed to restore original Azure context: $_"
                        }
                    }
                }
                else {
                    # Query all subscriptions
                    Write-Verbose "Querying all subscriptions via Az.Advisor"
                    Get-AzAdvisorRecommendation -Filter $filter | Where-Object $subcategoryFilter
                }

                foreach ($rec in $recommendations) {
                    # Parse extended properties for retirement information
                    $extProps = $null
                    $retirementFeatureName = $null
                    $retirementDate = $null

                    if ($rec.ExtendedProperty) {
                        # Reuse a previously-parsed ExtendedProperty if available to avoid redundant JSON parsing
                        if ($rec.PSObject.Properties.Name -contains 'ExtendedPropertyObject') {
                            $extProps = $rec.ExtendedPropertyObject
                        }
                        else {
                            try {
                                if ($rec.ExtendedProperty -is [string]) {
                                    # ExtendedProperty is JSON text; parse it once
                                    $extProps = $rec.ExtendedProperty | ConvertFrom-Json
                                }
                                elseif ($rec.ExtendedProperty -is [hashtable] -or $rec.ExtendedProperty -is [pscustomobject]) {
                                    # ExtendedProperty is already an object; no need to parse
                                    $extProps = $rec.ExtendedProperty
                                }

                                if ($extProps) {
                                    # Cache the parsed object on the recommendation to prevent re-parsing
                                    $rec | Add-Member -NotePropertyName ExtendedPropertyObject -NotePropertyValue $extProps -Force
                                }
                            }
                            catch {
                                Write-Verbose "Failed to parse ExtendedProperty: $_"
                                $extProps = $null
                            }
                        }

                        if ($extProps) {
                            $retirementFeatureName = $extProps.retirementFeatureName
                            $retirementDate = $extProps.retirementDate
                        }
                    }

                    # Check if this is a retirement recommendation
                    # Look in both the text and the extended properties
                    $isRetirement = $false
                    if ($rec.ShortDescriptionProblem -match 'retire|deprecat|end of life|eol|sunset|migration') {
                        $isRetirement = $true
                    }
                    elseif ($retirementFeatureName -or $retirementDate) {
                        $isRetirement = $true
                    }

                    # Extract ResourceId from ResourceMetadataResourceId property
                    $resourceId = $rec.ResourceMetadataResourceId
                    
                    $resourceType = if ($resourceId) {
                        if ($resourceId -match '/providers/([^/]+/[^/]+)(?:/|$)') {
                            $matches[1]
                        } else {
                            "N/A"
                        }
                    } else {
                        "N/A"
                    }

                    $resourceGroup = if ($resourceId) {
                        if ($resourceId -match '/resourceGroups/([^/]+)') {
                            $matches[1]
                        } else {
                            "N/A"
                        }
                    } else {
                        "N/A"
                    }

                    $subscriptionId = if ($resourceId) {
                        if ($resourceId -match '/subscriptions/([^/]+)') {
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

                    # Build description from extended properties
                    # Prefer retirementFeatureName, fall back to displayName
                    $description = if ($retirementFeatureName) {
                        if ($retirementDate) {
                            "$retirementFeatureName (Retirement Date: $retirementDate)"
                        }
                        else {
                            $retirementFeatureName
                        }
                    }
                    elseif ($extProps -and $extProps.displayName) {
                        $extProps.displayName
                    }
                    else {
                        $null
                    }

                    $allRecommendations.Add([PSCustomObject]@{
                        SubscriptionId   = $subscriptionId
                        ResourceId       = $resourceId
                        ResourceName     = if ($resourceId) { ($resourceId -split "/")[-1] } else { "N/A" }
                        ResourceType     = $resourceType
                        ResourceGroup    = $resourceGroup
                        Category         = $rec.Category
                        Impact           = $rec.Impact
                        Problem          = $rec.ShortDescriptionProblem
                        Solution         = $rec.ShortDescriptionSolution
                        Description      = $description
                        LastUpdated      = $rec.LastUpdated
                        IsRetirement     = $isRetirement
                        RecommendationId = $rec.Name
                        LearnMoreLink    = if ($rec.LearnMoreLink) { $rec.LearnMoreLink } else { $null }
                        ResourceLink     = $resourceLink
                    })
                }
            }
            catch {
                Write-Error "Failed to retrieve recommendations via Az.Advisor: $_"
            }
        }
    }

    end {
        return $allRecommendations.ToArray()
    }
}