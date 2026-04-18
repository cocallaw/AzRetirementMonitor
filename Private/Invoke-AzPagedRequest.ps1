function Invoke-AzPagedRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [hashtable]$Headers,

        [Parameter()]
        [int]$PageLimit = 100
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $nextUri = $Uri
    $pageCount = 0

    while ($nextUri) {
        $pageCount++
        if ($pageCount -gt $PageLimit) {
            Write-Warning "Pagination limit ($PageLimit pages) reached. Results may be incomplete."
            break
        }
        else {
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
    }

    return $results.ToArray()
}