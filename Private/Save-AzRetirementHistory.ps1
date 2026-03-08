function Save-AzRetirementHistory {
    <#
    .SYNOPSIS
    Saves the change tracking history to a JSON file.
    .DESCRIPTION
    Serializes the history object to JSON (depth 10) and writes it to the specified path,
    creating or overwriting the file.
    .PARAMETER Path
    Full path to the history JSON file.
    .PARAMETER History
    The history object (with Created and Snapshots properties) to persist.
    .OUTPUTS
    None. Writes a file to disk.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [PSCustomObject]$History
    )

    try {
        $History | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8 -Force
        Write-Verbose "Saved history to: $Path"
    }
    catch {
        Write-Warning "Failed to save history to $Path : $_"
    }
}
