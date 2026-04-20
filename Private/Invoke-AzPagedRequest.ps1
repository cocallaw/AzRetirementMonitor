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
    $allowedHosts = @("management.azure.com")
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

            if ($response.nextLink) {
                $parsedUri = $null
                $isValidNextLink = [System.Uri]::TryCreate(
                    $response.nextLink,
                    [System.UriKind]::Absolute,
                    [ref]$parsedUri
                )

                if (-not $isValidNextLink) {
                    Write-Error "Invalid nextLink URI: $($response.nextLink). Stopping pagination."
                    break
                }

                # Verify that URI returned is secure and in the list of $allowedHosts
                if ($parsedUri.Scheme -ne "https") {
                    Write-Error "Insecure nextLink scheme: $($parsedUri.Scheme). Stopping pagination."
                    break
                }

                if ($parsedUri.Host -notin $allowedHosts) {
                    Write-Error "Untrusted nextLink host: $($parsedUri.Host). Stopping pagination."
                    break
                }

                $nextUri = $parsedUri.AbsoluteUri
            } else {
                $nextUri = $null
            }
        }
    }

    return $results.ToArray()
}