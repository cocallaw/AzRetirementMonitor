function Save-AzRetirementHistory {
    <#
    .SYNOPSIS
    Saves the change tracking history to a JSON file
    .PARAMETER Path
    Path to the history JSON file
    .PARAMETER History
    The history object to save
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [PSCustomObject]$History
    )

    try {
        $History | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Force
        Write-Verbose "Saved history to: $Path"
    }
    catch {
        Write-Warning "Failed to save history to $Path : $_"
    }
}
