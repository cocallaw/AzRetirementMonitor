function Disconnect-AzRetirementMonitor {
<#
.SYNOPSIS
Disconnects from AzRetirementMonitor by clearing the stored access token
.DESCRIPTION
Clears the access token stored by Connect-AzRetirementMonitor. This does not affect 
your Azure CLI or Az.Accounts session - you remain logged in to Azure after disconnecting.

The SecureString token reference is cleared from module scope. PowerShell does not
provide deterministic memory clearing for managed strings created while preparing
HTTP headers.
.EXAMPLE
Disconnect-AzRetirementMonitor
Clears the stored access token

.OUTPUTS
None. Displays a success message when disconnection completes.
#>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    if ($script:AccessTokenSecureString) {
        $script:AccessTokenSecureString = $null
        Write-Host "Disconnected from AzRetirementMonitor successfully"
        Write-Verbose "Secure access token reference cleared from module memory"
    }
    else {
        Write-Verbose "No active connection to disconnect"
    }
}
