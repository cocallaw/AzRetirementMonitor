function New-AzRetirementSnapshot {
    <#
    .SYNOPSIS
    Creates a snapshot of current retirement recommendations for change tracking.
    .DESCRIPTION
    Aggregates the provided recommendation objects into a lightweight snapshot containing
    the timestamp, total count, per-impact-level counts, per-resource-type counts, and the
    list of resource IDs. The snapshot is used by Show-AzRetirementComparison and
    Save-AzRetirementHistory.
    .PARAMETER Recommendations
    Array of recommendation objects returned by Get-AzRetirementRecommendation. An empty
    collection is permitted and produces a snapshot with zero counts.
    .OUTPUTS
    PSCustomObject
    An object with properties: Timestamp (ISO 8601 string), TotalCount (int),
    ImpactCounts (hashtable), ResourceTypeCounts (hashtable), ResourceIds (string[]).
    #>
    # SuppressMessageAttribute: this private function only constructs an in-memory object;
    # no system state is changed, so ShouldProcess/ShouldContinue are not applicable.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
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

    # Track resource IDs - using List for better performance
    $resourceIds = [System.Collections.Generic.List[string]]::new()

    foreach ($rec in $Recommendations) {
        # Count by impact
        if ($rec.Impact) {
            if ($impactCounts.ContainsKey($rec.Impact)) {
                $impactCounts[$rec.Impact]++
            }
            else {
                Write-Warning "New-AzRetirementSnapshot: Unexpected Impact value '$($rec.Impact)' encountered. This value will be tracked but may not display correctly."
                $impactCounts[$rec.Impact] = 1
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
            $resourceIds.Add($rec.ResourceId)
        }
    }

    return [PSCustomObject]@{
        Timestamp          = (Get-Date).ToString('o')
        TotalCount         = $Recommendations.Count
        ImpactCounts       = $impactCounts
        ResourceTypeCounts = $resourceTypeCounts
        ResourceIds        = $resourceIds.ToArray()
    }
}
