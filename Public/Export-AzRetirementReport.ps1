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
                # Helper function to escape HTML to prevent XSS
                function ConvertTo-HtmlEncoded {
                    param([string]$Text)
                    if ([string]::IsNullOrEmpty($Text)) {
                        return $Text
                    }
                    return [System.Net.WebUtility]::HtmlEncode($Text)
                }
                
                $generatedTime = (Get-Date -AsUTC).ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
                $totalCount = $allRecs.Count
                
                # Define CSS for professional styling
                $css = @"
<style>
    body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        margin: 20px;
        background-color: #f5f5f5;
        color: #333;
    }
    .container {
        max-width: 1400px;
        margin: 0 auto;
        background-color: white;
        padding: 30px;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    h1 {
        color: #0078d4;
        border-bottom: 3px solid #0078d4;
        padding-bottom: 10px;
        margin-bottom: 20px;
    }
    .metadata {
        background-color: #f8f9fa;
        padding: 15px;
        border-radius: 5px;
        margin-bottom: 25px;
        border-left: 4px solid #0078d4;
    }
    .metadata p {
        margin: 5px 0;
        font-size: 14px;
    }
    .metadata strong {
        color: #0078d4;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 20px;
        font-size: 14px;
    }
    th {
        background-color: #0078d4;
        color: white;
        padding: 12px 8px;
        text-align: left;
        font-weight: 600;
        position: sticky;
        top: 0;
    }
    td {
        padding: 10px 8px;
        border-bottom: 1px solid #e0e0e0;
        vertical-align: top;
    }
    tr:hover {
        background-color: #f8f9fa;
    }
    .impact-high {
        color: #d13438;
        font-weight: bold;
    }
    .impact-medium {
        color: #ff8c00;
        font-weight: bold;
    }
    .impact-low {
        color: #107c10;
        font-weight: bold;
    }
    .resource-name {
        font-weight: 600;
        color: #0078d4;
    }
    .timestamp {
        color: #666;
        font-size: 12px;
    }
    a {
        color: #0078d4;
        text-decoration: none;
    }
    a:hover {
        text-decoration: underline;
    }
    .recommendation-id {
        font-family: 'Courier New', monospace;
        font-size: 12px;
        color: #666;
    }
    .footer {
        margin-top: 30px;
        padding-top: 20px;
        border-top: 1px solid #e0e0e0;
        text-align: center;
        color: #666;
        font-size: 12px;
    }
</style>
"@

                # Build HTML manually for better control over formatting
                $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure Service Retirement Report</title>
    $css
</head>
<body>
    <div class="container">
        <h1>Azure Service Retirement Report</h1>
        <div class="metadata">
            <p><strong>Generated:</strong> $generatedTime</p>
            <p><strong>Total Recommendations:</strong> $totalCount</p>
            <p><strong>Report Type:</strong> Service Retirement and Upgrade Recommendations</p>
            <p><strong>Impact Levels:</strong> Recommendations are categorized as High (critical, address immediately), Medium (important, moderate timeline), or Low (beneficial, lower priority). <a href="https://learn.microsoft.com/azure/advisor/advisor-overview" target="_blank" rel="noopener noreferrer">Learn more about Azure Advisor impact levels</a></p>
        </div>
        <table>
            <thead>
                <tr>
                    <th>Impact</th>
                    <th>Resource Name</th>
                    <th>Resource Type</th>
                    <th>Problem</th>
                    <th>Solution</th>
                    <th>Subscription ID</th>
                    <th>Learn More</th>
                    <th>Resource Link</th>
                </tr>
            </thead>
            <tbody>
"@

                # Add table rows - collect in array for better performance
                $tableRows = foreach ($rec in $allRecs) {
                    # HTML encode all user-provided data to prevent XSS
                    $encodedResourceName = ConvertTo-HtmlEncoded $rec.ResourceName
                    $encodedResourceType = ConvertTo-HtmlEncoded $rec.ResourceType
                    $encodedImpact = ConvertTo-HtmlEncoded $rec.Impact
                    $encodedProblem = ConvertTo-HtmlEncoded $rec.Problem
                    $encodedSolution = ConvertTo-HtmlEncoded $rec.Solution
                    $encodedSubscriptionId = ConvertTo-HtmlEncoded $rec.SubscriptionId
                    
                    # Validate and sanitize CSS class name to prevent CSS injection
                    $impactClass = switch ($rec.Impact) {
                        "High" { "impact-high" }
                        "Medium" { "impact-medium" }
                        "Low" { "impact-low" }
                        default { "" }
                    }
                    
                    # Build learn more link with proper encoding and validation
                    $encodedLearnMoreLink = if ($rec.LearnMoreLink) {
                        $url = $rec.LearnMoreLink
                        # Validate URL starts with http:// or https:// to prevent javascript: protocol injection
                        if ($url -imatch '^https?://') {
                            $encodedUrl = ConvertTo-HtmlEncoded $url
                            "<a href='$encodedUrl' target='_blank' rel='noopener noreferrer'>Documentation</a>"
                        } else {
                            ConvertTo-HtmlEncoded "Invalid URL"
                        }
                    } else {
                        "N/A"
                    }
                    
                    # Build Resource link with proper encoding and validation
                    $encodedResourceLink = if ($rec.ResourceLink) {
                        $url = $rec.ResourceLink
                        # Validate URL starts with http:// or https:// to prevent javascript: protocol injection
                        if ($url -imatch '^https?://') {
                            $encodedUrl = ConvertTo-HtmlEncoded $url
                            "<a href='$encodedUrl' target='_blank' rel='noopener noreferrer'>View Resource</a>"
                        } else {
                            ConvertTo-HtmlEncoded "Invalid URL"
                        }
                    } else {
                        "N/A"
                    }
                    
                    # Output row HTML
                    @"
                <tr>
                    <td class="$impactClass">$encodedImpact</td>
                    <td class="resource-name">$encodedResourceName</td>
                    <td>$encodedResourceType</td>
                    <td>$encodedProblem</td>
                    <td>$encodedSolution</td>
                    <td><span class="recommendation-id">$encodedSubscriptionId</span></td>
                    <td>$encodedLearnMoreLink</td>
                    <td>$encodedResourceLink</td>
                </tr>
"@
                }
                
                # Join all rows efficiently
                $htmlContent += ($tableRows -join "")

                # Close HTML
                $htmlContent += @"
            </tbody>
        </table>
        <div class="footer">
            <p>Generated by AzRetirementMonitor | Azure Service Retirement Monitoring Tool</p>
        </div>
    </div>
</body>
</html>
"@

                $htmlContent | Out-File $OutputPath -Encoding utf8
            }
        }

        Write-Verbose "Report exported to $OutputPath"
    }
}