function Export-AzRetirementReport {
<#
.SYNOPSIS
Exports retirement recommendations to CSV, JSON, or HTML
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]$Recommendations,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [ValidateSet("CSV", "JSON", "HTML")]
        [string]$Format = "CSV"
    )

    begin {
        $allRecs = @()
    }

    process {
        $allRecs += $Recommendations
    }

    end {
        switch ($Format) {
            "CSV" {
                $allRecs | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
            }
            "JSON" {
                $allRecs | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8
            }
            "HTML" {
                $allRecs |
                    ConvertTo-Html `
                        -Title "Azure Service Retirement Report" `
                        -PreContent "<h1>Azure Service Retirement Report</h1><p>Generated: $(Get-Date)</p>" |
                    Out-File $OutputPath -Encoding utf8
            }
        }

        Write-Verbose "Report exported to $OutputPath"
    }
}