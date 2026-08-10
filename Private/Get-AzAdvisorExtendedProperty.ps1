function Get-AzAdvisorExtendedProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Recommendation
    )

    if (
        $Recommendation.PSObject.Properties.Name -contains 'ExtendedPropertyObject' -and
        $null -ne $Recommendation.ExtendedPropertyObject
    ) {
        return $Recommendation.ExtendedPropertyObject
    }

    $extendedProperty = if ($Recommendation.PSObject.Properties.Name -contains 'ExtendedProperty') {
        $Recommendation.ExtendedProperty
    }
    elseif ($Recommendation.PSObject.Properties.Name -contains 'ExtendedProperties') {
        $Recommendation.ExtendedProperties
    }

    $extendedPropertyObject = $null
    if ($extendedProperty) {
        try {
            if ($extendedProperty -is [string]) {
                $extendedPropertyObject = $extendedProperty | ConvertFrom-Json
            }
            elseif (
                $extendedProperty.PSObject.Properties.Name -contains 'AdditionalProperties' -and
                $null -ne $extendedProperty.AdditionalProperties
            ) {
                # Generated Az.Advisor models expose custom fields through this dictionary.
                $extendedPropertyObject = $extendedProperty.AdditionalProperties
            }
            else {
                # Az.Advisor versions can return an already-materialized property object.
                $extendedPropertyObject = $extendedProperty
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
