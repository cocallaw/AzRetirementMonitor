function Disconnect-AzRetirementMonitor {
<#
.SYNOPSIS
Disconnects from AzRetirementMonitor by clearing the stored access token
.DESCRIPTION
Clears the access token stored by Connect-AzRetirementMonitor. This does not affect 
your Azure CLI or Az.Accounts session - you remain logged in to Azure after disconnecting.

The token is cleared from memory by setting the module-scoped variable to $null.
Since PowerShell access tokens are session-based and time-limited, this is sufficient
for cleanup. The token cannot be recovered after clearing.
.EXAMPLE
Disconnect-AzRetirementMonitor
Clears the stored access token

.OUTPUTS
None. Displays a success message when disconnection completes.
#>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    if ($script:AccessToken) {
        # Clear the token from memory
        # Note: PowerShell doesn't have secure string clearing for regular strings,
        # but since these are time-limited session tokens (not long-lived credentials),
        # setting to $null is acceptable. The token will be garbage collected.
        $script:AccessToken = $null
        Write-Host "Disconnected from AzRetirementMonitor successfully"
        Write-Verbose "Access token cleared from module memory"
    }
    else {
        Write-Verbose "No active connection to disconnect"
    }
}
