function Test-AzRetirementMonitorToken {
    <#
    .SYNOPSIS
    Tests if the stored access token is valid and not expired
    .DESCRIPTION
    Decodes the JWT token and checks if it has expired
    Returns $true if token is valid, $false if expired or invalid
    #>
    [CmdletBinding()]
    param()

    if (-not $script:AccessToken) {
        return $false
    }

    try {
        # JWT tokens have 3 parts separated by dots: header.payload.signature
        $tokenParts = $script:AccessToken -split '\.'
        
        if ($tokenParts.Count -ne 3) {
            Write-Verbose "Token format is invalid"
            return $false
        }

        # Decode the payload (second part)
        $payload = $tokenParts[1]
        
        # Base64URL to Base64 conversion (add padding if needed)
        $base64 = $payload.Replace('-', '+').Replace('_', '/')
        switch ($base64.Length % 4) {
            0 { break }
            2 { $base64 += '==' }
            3 { $base64 += '=' }
            default { 
                Write-Verbose "Invalid Base64URL string length"
                return $false
            }
        }

        # Decode from Base64 and convert from JSON
        $payloadJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
        $tokenData = $payloadJson | ConvertFrom-Json

        # Check expiration time (exp claim is in Unix timestamp format)
        if ($tokenData.exp) {
            $expirationTime = [DateTimeOffset]::FromUnixTimeSeconds($tokenData.exp).DateTime
            $currentTime = [DateTime]::UtcNow

            if ($currentTime -ge $expirationTime) {
                Write-Verbose "Token has expired at $expirationTime UTC"
                return $false
            }
            
            Write-Verbose "Token is valid until $expirationTime UTC"
            return $true
        }
        else {
            Write-Verbose "Token does not contain expiration claim"
            return $false
        }
    }
    catch {
        Write-Verbose "Failed to decode token: $_"
        return $false
    }
}
