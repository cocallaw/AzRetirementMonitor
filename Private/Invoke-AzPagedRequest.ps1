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

            if ($response.nextLink){
                $parsedUri = [System.Uri]::new($response.nextLink)
                # Verify that URI returned is secure and in the list of $allowedHosts
                if ($parsedUri.Scheme -ne "https" -or $parsedUri.Host -notin $allowedHosts) {
                    Write-Error "Untrusted nextLink host: $($parsedUri.Host). Stopping pagination."
                    break
                }
                $nextUri = $response.nextLink
            } else {
                $nextUri = $null
            }
        }
    }

    return $results.ToArray()
}