function Invoke-AzPagedRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Headers
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $nextUri = $Uri

    while ($nextUri) {
        Write-Verbose "Requesting page: $nextUri"

        try {
            $response = Invoke-RestMethod `
                -Uri $nextUri `
                -Headers $Headers `
                -Method Get `
                -ErrorAction Stop
        }
        catch {
            Write-Error "Azure API request failed for '$nextUri': $_"
            return $results.ToArray()
        }

        if ($response.value) {
            $results.AddRange($response.value)
        }

        $nextUri = $response.nextLink
    }

    return $results.ToArray()
}