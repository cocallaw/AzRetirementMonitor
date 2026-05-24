function Resolve-ExtendedProperty {
    <#
    .SYNOPSIS
    Parses and caches the ExtendedProperty on a recommendation object.

    .DESCRIPTION
    Handles ExtendedProperty as a JSON string, hashtable, or PSCustomObject.
    Returns the parsed object and attaches it as ExtendedPropertyObject on the
    input object for downstream reuse. Returns $null on parse failure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSObject]$Recommendation
    )

    if (-not $Recommendation.ExtendedProperty) {
        return $null
    }

    # Return cached value if already resolved
    if ($Recommendation.PSObject.Properties.Name -contains 'ExtendedPropertyObject') {
        return $Recommendation.ExtendedPropertyObject
    }

    $extProps = $null
    try {
        if ($Recommendation.ExtendedProperty -is [string]) {
            $extProps = $Recommendation.ExtendedProperty | ConvertFrom-Json
        }
        elseif ($Recommendation.ExtendedProperty -is [hashtable] -or $Recommendation.ExtendedProperty -is [pscustomobject]) {
            $extProps = $Recommendation.ExtendedProperty
        }

        if ($extProps) {
            $Recommendation | Add-Member -NotePropertyName ExtendedPropertyObject -NotePropertyValue $extProps -Force
        }
    }
    catch {
        Write-Verbose "Failed to parse ExtendedProperty: $_"
        $extProps = $null
    }

    return $extProps
}
