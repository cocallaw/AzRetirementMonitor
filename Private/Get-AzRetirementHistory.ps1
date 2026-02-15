function Get-AzRetirementHistory {
    <#
    .SYNOPSIS
    Loads the change tracking history from a JSON file
    .PARAMETER Path
    Path to the history JSON file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        try {
            $content = Get-Content -Path $Path -Raw | ConvertFrom-Json
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
