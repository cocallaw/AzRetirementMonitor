function Show-AzRetirementComparison {
    <#
    .SYNOPSIS
    Displays a comparison between current and previous snapshots
    .PARAMETER CurrentSnapshot
    Current snapshot object
    .PARAMETER PreviousSnapshot
    Previous snapshot object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$CurrentSnapshot,

        [Parameter()]
        [PSCustomObject]$PreviousSnapshot
    )

    Write-Host "`n=== Azure Retirement Monitor - Change Tracking ===" -ForegroundColor Cyan
    Write-Host "Current Run: $($CurrentSnapshot.Timestamp)" -ForegroundColor Gray

    if ($PreviousSnapshot) {
        Write-Host "Previous Run: $($PreviousSnapshot.Timestamp)" -ForegroundColor Gray
        
        # Total count comparison
        $totalChange = $CurrentSnapshot.TotalCount - $PreviousSnapshot.TotalCount
        $totalChangeSymbol = if ($totalChange -gt 0) { "+" } elseif ($totalChange -lt 0) { "" } else { "" }
        $totalChangeColor = if ($totalChange -gt 0) { "Red" } elseif ($totalChange -lt 0) { "Green" } else { "Gray" }
        
        Write-Host "`nTotal Recommendations: $($CurrentSnapshot.TotalCount) " -NoNewline
        if ($totalChange -ne 0) {
            Write-Host "($totalChangeSymbol$totalChange)" -ForegroundColor $totalChangeColor
        } else {
            Write-Host "(no change)" -ForegroundColor Gray
        }

        # Impact level comparison
        Write-Host "`nBy Impact Level:" -ForegroundColor Yellow
        foreach ($impact in @('High', 'Medium', 'Low')) {
            # ImpactCounts may be a hashtable (freshly created) or PSCustomObject (loaded from JSON).
            # Use -is [hashtable] to select the correct access method for both cases.
            $current = if ($CurrentSnapshot.ImpactCounts -is [hashtable]) {
                if ($CurrentSnapshot.ImpactCounts.ContainsKey($impact)) { $CurrentSnapshot.ImpactCounts[$impact] } else { 0 }
            } else {
                $val = $CurrentSnapshot.ImpactCounts.$impact; if ($null -ne $val) { [int]$val } else { 0 }
            }
            $previous = if ($PreviousSnapshot.ImpactCounts -is [hashtable]) {
                if ($PreviousSnapshot.ImpactCounts.ContainsKey($impact)) { $PreviousSnapshot.ImpactCounts[$impact] } else { 0 }
            } else {
                $val = $PreviousSnapshot.ImpactCounts.$impact; if ($null -ne $val) { [int]$val } else { 0 }
            }
            $change = $current - $previous
            $changeSymbol = if ($change -gt 0) { "+" } elseif ($change -lt 0) { "" } else { "" }
            $changeColor = if ($change -gt 0) { "Red" } elseif ($change -lt 0) { "Green" } else { "Gray" }
            
            Write-Host "  $impact : $current " -NoNewline
            if ($change -ne 0) {
                Write-Host "($changeSymbol$change)" -ForegroundColor $changeColor
            } else {
                Write-Host "(no change)" -ForegroundColor Gray
            }
        }

        # Resource changes
        $currentResourceIds = @($CurrentSnapshot.ResourceIds)
        $previousResourceIds = @($PreviousSnapshot.ResourceIds)
        
        $newResources = $currentResourceIds | Where-Object { $_ -notin $previousResourceIds }
        $resolvedResources = $previousResourceIds | Where-Object { $_ -notin $currentResourceIds }
        
        if ($newResources.Count -gt 0 -or $resolvedResources.Count -gt 0) {
            Write-Host "`nResource Changes:" -ForegroundColor Yellow
            
            if ($newResources.Count -gt 0) {
                Write-Host "  New Issues: $($newResources.Count)" -ForegroundColor Red
                foreach ($resourceId in $newResources) {
                    if (-not [string]::IsNullOrWhiteSpace($resourceId) -and $resourceId.Contains("/")) {
                        $resourceName = ($resourceId -split "/")[-1]
                    } else {
                        $resourceName = $resourceId
                    }
                    Write-Host "    + $resourceName" -ForegroundColor Red
                }
            }
            
            if ($resolvedResources.Count -gt 0) {
                Write-Host "  Resolved: $($resolvedResources.Count)" -ForegroundColor Green
                foreach ($resourceId in $resolvedResources) {
                    if (-not [string]::IsNullOrWhiteSpace($resourceId) -and $resourceId.Contains("/")) {
                        $resourceName = ($resourceId -split "/")[-1]
                    } else {
                        $resourceName = $resourceId
                    }
                    Write-Host "    - $resourceName" -ForegroundColor Green
                }
            }
        }
    }
    else {
        Write-Host "`nThis is the first run with change tracking enabled." -ForegroundColor Yellow
        Write-Host "Total Recommendations: $($CurrentSnapshot.TotalCount)" -ForegroundColor Gray
        
        Write-Host "`nBy Impact Level:" -ForegroundColor Yellow
        foreach ($impact in @('High', 'Medium', 'Low')) {
            $count = $CurrentSnapshot.ImpactCounts.$impact
            Write-Host "  $impact : $count" -ForegroundColor Gray
        }
    }

    Write-Host "`n=================================================" -ForegroundColor Cyan
}
