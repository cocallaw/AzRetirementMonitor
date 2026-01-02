function Invoke-AzPagedRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [hashtable]$Headers
    )

    $results = @()
    $nextUri = $Uri

    while ($nextUri) {
        Write-Verbose "Requesting page: $nextUri"

        $response = Invoke-RestMethod `
            -Uri $nextUri `
            -Headers $Headers `
            -Method Get `
            -ErrorAction Stop

        if ($response.value) {
            $results += $response.value
        }

        $nextUri = $response.nextLink
    }

    return $results
}