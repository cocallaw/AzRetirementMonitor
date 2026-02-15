function New-AzRetirementSnapshot {
    <#
    .SYNOPSIS
    Creates a snapshot of current retirement recommendations for tracking
    .PARAMETER Recommendations
    Array of recommendation objects
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Recommendations
    )

    # Count by impact level
    $impactCounts = @{
        High   = 0
        Medium = 0
        Low    = 0
    }

    # Count by resource type
    $resourceTypeCounts = @{}

    # Track resource IDs
    $resourceIds = @()

    foreach ($rec in $Recommendations) {
        # Count by impact
        if ($rec.Impact) {
            if ($impactCounts.ContainsKey($rec.Impact)) {
                $impactCounts[$rec.Impact]++
            }
            else {
                Write-Warning "New-AzRetirementSnapshot: Unexpected Impact value '$($rec.Impact)' encountered. This value will be ignored in impact counts."
            }
        }

        # Count by resource type
        if ($rec.ResourceType) {
            if (-not $resourceTypeCounts.ContainsKey($rec.ResourceType)) {
                $resourceTypeCounts[$rec.ResourceType] = 0
            }
            $resourceTypeCounts[$rec.ResourceType]++
        }

        # Track resource IDs
        if ($rec.ResourceId) {
            $resourceIds += $rec.ResourceId
        }
    }

    return [PSCustomObject]@{
        Timestamp          = (Get-Date).ToString('o')
        TotalCount         = $Recommendations.Count
        ImpactCounts       = $impactCounts
        ResourceTypeCounts = $resourceTypeCounts
        ResourceIds        = $resourceIds
    }
}
