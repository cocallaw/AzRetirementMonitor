function Connect-AzRetirementMonitor {
<#
.SYNOPSIS
Authenticates to Azure and stores an access token
.DESCRIPTION
Uses Azure CLI (default) or Az.Accounts to authenticate and obtain an access token
scoped to https://management.azure.com for read-only Azure Advisor API access.

The token obtained is used exclusively for:
- Reading Azure Advisor recommendations (Microsoft.Advisor/recommendations/read)
- Reading Azure Advisor metadata (Microsoft.Advisor/metadata/read)
- Listing subscriptions (Microsoft.Resources/subscriptions/read)

Required RBAC permissions: Reader role at subscription or resource group scope

The token is stored in a module-scoped variable for the duration of the PowerShell session
and is validated for proper audience (https://management.azure.com) before use.
.PARAMETER UseAzCLI
Use Azure CLI (az) for authentication. This is the default.
.PARAMETER UseAzPowerShell
Use Az.Accounts PowerShell module for authentication.
.EXAMPLE
Connect-AzRetirementMonitor
Connects using Azure CLI (default method)
.EXAMPLE
Connect-AzRetirementMonitor -UseAzPowerShell
Connects using Az.Accounts PowerShell module
.OUTPUTS
None. Displays a success message when authentication completes.
#>
    [CmdletBinding(DefaultParameterSetName = 'AzCLI')]
    [OutputType([void])]
    param(
        [Parameter(ParameterSetName = 'AzCLI')]
        [switch]$UseAzCLI,

        [Parameter(ParameterSetName = 'AzPS')]
        [switch]$UseAzPowerShell
    )

    try {
        if ($UseAzPowerShell) {
            if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
                throw "Az.Accounts module is not installed."
            }

            Import-Module Az.Accounts -ErrorAction Stop
            $context = Get-AzContext
            if (-not $context) {
                throw "Run Connect-AzAccount first."
            }
            Write-Verbose "Using Az.Accounts for authentication"
            Write-Verbose "Requesting token scoped to https://management.azure.com for read-only Azure Advisor access"
            $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
            $script:AccessToken = $token.Token
        }
        else {
            $null = & az account show 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Not logged into Azure CLI. Run 'az login'."
            }
            Write-Verbose "Using Azure CLI for authentication"
            Write-Verbose "Requesting token scoped to https://management.azure.com for read-only Azure Advisor access"
            $script:AccessToken = & az account get-access-token `
                --resource https://management.azure.com `
                --query accessToken `
                --output tsv
        }

        Write-Host "Authenticated to Azure successfully"
        Write-Verbose "Token is scoped to https://management.azure.com for Azure Resource Manager API access"
        Write-Verbose "This module only uses read-only operations: Microsoft.Advisor/recommendations/read and Microsoft.Advisor/metadata/read"
    }
    catch {
        Write-Error "Authentication failed: $_"
    }
}