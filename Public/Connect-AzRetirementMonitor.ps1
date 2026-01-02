function Connect-AzRetirementMonitor {
<#
.SYNOPSIS
Authenticates to Azure and stores an access token
.DESCRIPTION
Uses Azure CLI (default) or Az.Accounts to authenticate
#>
    [CmdletBinding(DefaultParameterSetName = 'AzCLI')]
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
            $token = Get-AzAccessToken -ResourceUrl "https://management.azure.com"
            $script:AccessToken = $token.Token
        }
        else {
            $null = & az account show 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Not logged into Azure CLI. Run 'az login'."
            }
            Write-Verbose "Using Azure CLI for authentication"
            $script:AccessToken = & az account get-access-token `
                --resource https://management.azure.com `
                --query accessToken `
                --output tsv
        }

        Write-Host "Authenticated to Azure successfully"
    }
    catch {
        Write-Error "Authentication failed: $_"
    }
}