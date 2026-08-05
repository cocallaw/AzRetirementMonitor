function Get-AzAdvisorExtendedProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Recommendation
    )

    if ($Recommendation.PSObject.Properties.Name -contains 'ExtendedPropertyObject') {
        return $Recommendation.ExtendedPropertyObject
    }

    $extendedPropertyObject = $null
    if ($Recommendation.ExtendedProperty) {
        try {
            if ($Recommendation.ExtendedProperty -is [string]) {
                $extendedPropertyObject = $Recommendation.ExtendedProperty | ConvertFrom-Json
            }
            else {
                # Az.Advisor versions can return an already-materialized property object.
                $extendedPropertyObject = $Recommendation.ExtendedProperty
            }
        }
        catch {
            Write-Verbose "Failed to parse ExtendedProperty: $_"
        }
    }

    $Recommendation | Add-Member `
        -NotePropertyName ExtendedPropertyObject `
        -NotePropertyValue $extendedPropertyObject `
        -Force

    return $extendedPropertyObject
}
