function Disconnect-AzRetirementMonitor {
<#
.SYNOPSIS
Disconnects from AzRetirementMonitor by clearing the stored access token
.DESCRIPTION
Clears the access token stored by Connect-AzRetirementMonitor. This does not affect the Azure CLI or Az.Accounts session.
.EXAMPLE
Disconnect-AzRetirementMonitor
Clears the stored access token
#>
    [CmdletBinding()]
    param()

    if ($script:AccessToken) {
        $script:AccessToken = $null
        Write-Host "Disconnected from AzRetirementMonitor successfully"
    }
    else {
        Write-Verbose "No active connection to disconnect"
    }
}
