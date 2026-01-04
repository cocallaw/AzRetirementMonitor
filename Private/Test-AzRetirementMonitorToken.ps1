function Test-AzRetirementMonitorToken {
    <#
    .SYNOPSIS
    Tests if the stored access token is valid and not expired
    .DESCRIPTION
    Decodes the JWT token and validates:
    1. Token structure (3 parts: header.payload.signature)
    2. Audience claim (must be https://management.azure.com or https://management.core.windows.net)
    3. Expiration claim (must not be expired, with 5-minute buffer)
    
    This function performs basic JWT validation without signature verification.
    Signature verification is not performed because:
    - Tokens come from trusted Azure authentication sources (Azure CLI or Az.Accounts)
    - Azure validates signatures when tokens are used for API calls
    - We only use tokens immediately and don't persist them
    
    Returns $true if token is valid, $false if expired, invalid, or incorrectly scoped
    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
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

        # Validate audience claim - must be scoped to Azure Resource Manager
        # The audience (aud) claim identifies the intended recipient of the token
        if ($tokenData.aud) {
            $validAudiences = @(
                'https://management.azure.com',
                'https://management.azure.com/',
                'https://management.core.windows.net',
                'https://management.core.windows.net/'
            )
            
            if ($tokenData.aud -notin $validAudiences) {
                Write-Verbose "Token audience '$($tokenData.aud)' is not valid for Azure Resource Manager API calls"
                return $false
            }
            
            Write-Verbose "Token audience validated: $($tokenData.aud)"
        }
        else {
            Write-Verbose "Token does not contain audience (aud) claim"
            return $false
        }

        # Check expiration time (exp claim is in Unix timestamp format)
        if ($tokenData.exp) {
            $expirationTime = [DateTimeOffset]::FromUnixTimeSeconds($tokenData.exp)
            $currentTime = [DateTimeOffset]::UtcNow
            $expirationBuffer = [TimeSpan]::FromMinutes(5)

            if ($currentTime -ge $expirationTime.Subtract($expirationBuffer)) {
                Write-Verbose "Token has expired or is about to expire at $($expirationTime.DateTime) UTC"
                return $false
            }
            
            Write-Verbose "Token is valid until $($expirationTime.DateTime) UTC"
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
