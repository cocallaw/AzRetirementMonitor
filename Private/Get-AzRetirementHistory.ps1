function Get-AzRetirementHistory {
    <#
    .SYNOPSIS
    Loads the change tracking history from a JSON file.
    .DESCRIPTION
    Reads the JSON file at the specified path and returns the deserialized history object.
    Returns $null if the file does not exist or cannot be parsed.
    .PARAMETER Path
    Full path to the history JSON file.
    .OUTPUTS
    PSCustomObject
    An object with Created (string) and Snapshots (array) properties, or $null if the file is missing or invalid.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        try {
            $content = Get-Content -Path $Path -Raw -Encoding utf8 | ConvertFrom-Json
            Write-Verbose "Loaded history from: $Path"
            return $content
        }
        catch {
            Write-Warning "Failed to load history from $Path : $_"
            return $null
        }
    }
    else {
        Write-Verbose "No existing history file found at: $Path"
        return $null
    }
}
