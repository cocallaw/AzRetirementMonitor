function Connect-AzRetirementMonitor {
<#
.SYNOPSIS
Authenticates to Azure and stores an access token for REST API access
.DESCRIPTION
⚠️  IMPORTANT: This command is ONLY needed when using Get-AzRetirementRecommendation with the -UseAPI switch.

By default, Get-AzRetirementRecommendation uses the Az.Advisor PowerShell module, which does NOT require
this connection command. Simply use Connect-AzAccount and then call Get-AzRetirementRecommendation.

This command is only for API-based access and requires the -UsingAPI switch to proceed.

Uses Azure CLI (default) or Az.Accounts to authenticate and obtain an access token
scoped to https://management.azure.com for read-only Azure Advisor API access.

The token obtained is used exclusively for:
- Reading Azure Advisor recommendations (Microsoft.Advisor/recommendations/read)
- Reading Azure Advisor metadata (Microsoft.Advisor/metadata/read)
- Listing subscriptions (Microsoft.Resources/subscriptions/read)

Required RBAC permissions: Reader role at subscription or resource group scope

The token is stored in a module-scoped variable for the duration of the PowerShell session
and is validated for proper audience (https://management.azure.com) before use.
.PARAMETER UsingAPI
Required switch to confirm you intend to use API-based access. This prevents accidentally 
connecting when using the default Az.Advisor module method.
.PARAMETER UseAzCLI
Use Azure CLI (az) for authentication. This is the default for API access.
.PARAMETER UseAzPowerShell
Use Az.Accounts PowerShell module for authentication.
.EXAMPLE
Connect-AzRetirementMonitor -UsingAPI
Connects using Azure CLI for API-based access
.EXAMPLE
Connect-AzRetirementMonitor -UsingAPI -UseAzPowerShell
Connects using Az.Accounts PowerShell module for API-based access
.OUTPUTS
None. Displays a success message when authentication completes.
#>
    [CmdletBinding(DefaultParameterSetName = 'AzCLI')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [switch]$UsingAPI,

        [Parameter(ParameterSetName = 'AzCLI')]
        [switch]$UseAzCLI,

        [Parameter(ParameterSetName = 'AzPS')]
        [switch]$UseAzPowerShell
    )

    Write-Host "Connecting for API-based access..."
    Write-Verbose "This connection is only needed when using Get-AzRetirementRecommendation -UseAPI"

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
            
            # Starting with Az.Accounts 5.0.0, the Token property is a SecureString
            # We need to convert it to plain text for use in Authorization headers
            # This conversion is necessary because REST API calls require the token as a string
            if ($token.Token -is [System.Security.SecureString]) {
                # Use PSCredential to convert SecureString to plain text
                $credential = New-Object System.Management.Automation.PSCredential("token", $token.Token)
                $script:AccessToken = $credential.GetNetworkCredential().Password
            }
            else {
                # Backwards compatibility for older Az.Accounts versions that return plain text
                $script:AccessToken = $token.Token
            }

            if ([string]::IsNullOrWhiteSpace($script:AccessToken)) {
                $script:AccessToken = $null
                throw "Failed to acquire access token from Az.Accounts. Ensure you are connected with 'Connect-AzAccount'."
            }
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

            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($script:AccessToken)) {
                $script:AccessToken = $null
                throw "Failed to acquire access token from Azure CLI. Ensure you are logged in with 'az login' and have access to the target subscription."
            }
        }

        Write-Host "Authenticated to Azure successfully for API access"
        Write-Verbose "Token is scoped to https://management.azure.com for Azure Resource Manager API access"
        Write-Verbose "This module only uses read-only operations: Microsoft.Advisor/recommendations/read and Microsoft.Advisor/metadata/read"
        Write-Host ""
        Write-Host "To use API mode, run: Get-AzRetirementRecommendation -UseAPI" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Authentication failed: $_"
    }
}