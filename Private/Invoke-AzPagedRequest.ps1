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
            $response = $null
            $retryCount = 0
            $maxRetries = 3

            while ($retryCount -le $maxRetries) {
                try {
                    $response = Invoke-RestMethod `
                        -Uri $nextUri `
                        -Headers $Headers `
                        -Method Get `
                        -ErrorAction Stop
                    break
                }
                catch {
                    $statusCode = $null
                    if ($_.Exception.Response) {
                        $statusCode = [int]$_.Exception.Response.StatusCode
                    }

                    $retryable = $statusCode -in @(429, 500, 502, 503, 504)
                    if ($retryable -and $retryCount -lt $maxRetries) {
                        $retryAfter = $null
                        if ($_.Exception.Response.Headers) {
                            $retryAfter = $_.Exception.Response.Headers["Retry-After"]
                        }
                        if ($retryAfter) {
                            $delay = [int]$retryAfter
                        }
                        else {
                            $delay = [math]::Pow(2, $retryCount)
                        }
                        Write-Verbose "Request failed with status $statusCode. Retrying in $delay seconds ($($retryCount + 1)/$maxRetries)..."
                        Start-Sleep -Seconds $delay
                        $retryCount++
                    }
                    else {
                        Write-Error "Azure API request failed for ${nextUri}: $_"
                        return $results.ToArray()
                    }
                }
            }

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