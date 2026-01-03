function Invoke-AzPagedRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [hashtable]$Headers
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $nextUri = $Uri

    while ($nextUri) {
        Write-Verbose "Requesting page: $nextUri"

        $response = Invoke-RestMethod `
            -Uri $nextUri `
            -Headers $Headers `
            -Method Get `
            -ErrorAction Stop

        if ($response.value) {
            $results.AddRange($response.value)
        }

        $nextUri = $response.nextLink
    }

    return $results.ToArray()
}