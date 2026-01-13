function Export-AzRetirementReport {
<#
.SYNOPSIS
Exports retirement recommendations to CSV, JSON, or HTML
.DESCRIPTION
Exports retirement recommendations retrieved from Get-AzRetirementRecommendation to various
formats for reporting and analysis. Works with recommendations from both the default Az.Advisor
method and the API method.
.PARAMETER Recommendations
Recommendation objects from Get-AzRetirementRecommendation (accepts pipeline input)
.PARAMETER OutputPath
File path for the exported report
.PARAMETER Format
Export format: CSV, JSON, or HTML (default: CSV)
.EXAMPLE
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.csv" -Format CSV
Exports recommendations to CSV format
.EXAMPLE
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.html" -Format HTML
Exports recommendations to HTML format
.EXAMPLE
Get-AzRetirementRecommendation -UseAPI | Export-AzRetirementReport -OutputPath "report.json" -Format JSON
Exports API-sourced recommendations to JSON format
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
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
        if (-not $PSCmdlet.ShouldProcess($OutputPath, "Export $($allRecs.Count) retirement recommendation(s) as $Format")) {
            return
        }

        # Transform data to use Description in Solution column for Az.Advisor mode
        # (when Problem and Solution are the same, Description usually has better info)
        # This transformation is used for CSV, JSON, and HTML formats
        $transformedRecs = $allRecs | ForEach-Object {
            # Use Description if Problem == Solution and Description exists
            # This indicates Az.Advisor mode where generic text is duplicated
            $solutionValue = if ($_.Problem -eq $_.Solution -and $_.Description) {
                $_.Description
            } else {
                $_.Solution
            }
            
            # Create new object with properly converted properties
            # This ensures all properties are strings (not arrays) for proper export
            [PSCustomObject]@{
                SubscriptionId   = $_.SubscriptionId
                ResourceId       = $_.ResourceId
                ResourceName     = $_.ResourceName
                ResourceType     = $_.ResourceType
                ResourceGroup    = $_.ResourceGroup
                Category         = $_.Category
                Impact           = $_.Impact
                Problem          = $_.Problem
                Description      = $_.Description
                LastUpdated      = $_.LastUpdated
                IsRetirement     = $_.IsRetirement
                RecommendationId = $_.RecommendationId
                LearnMoreLink    = $_.LearnMoreLink
                ResourceLink     = $_.ResourceLink
                Solution         = $solutionValue
            }
        }

        switch ($Format) {
            "CSV" {
                # Sanitize potential formula injections for CSV consumers (e.g., Excel)
                $safeRecs = $transformedRecs | ForEach-Object {
                    # Create new object with sanitized values
                    $rec = $_
                    [PSCustomObject]@{
                        SubscriptionId   = if ($rec.SubscriptionId -is [string] -and $rec.SubscriptionId.Length -gt 0 -and $rec.SubscriptionId[0] -in '=','+','-','@') { "'" + $rec.SubscriptionId } else { $rec.SubscriptionId }
                        ResourceId       = if ($rec.ResourceId -is [string] -and $rec.ResourceId.Length -gt 0 -and $rec.ResourceId[0] -in '=','+','-','@') { "'" + $rec.ResourceId } else { $rec.ResourceId }
                        ResourceName     = if ($rec.ResourceName -is [string] -and $rec.ResourceName.Length -gt 0 -and $rec.ResourceName[0] -in '=','+','-','@') { "'" + $rec.ResourceName } else { $rec.ResourceName }
                        ResourceType     = if ($rec.ResourceType -is [string] -and $rec.ResourceType.Length -gt 0 -and $rec.ResourceType[0] -in '=','+','-','@') { "'" + $rec.ResourceType } else { $rec.ResourceType }
                        ResourceGroup    = if ($rec.ResourceGroup -is [string] -and $rec.ResourceGroup.Length -gt 0 -and $rec.ResourceGroup[0] -in '=','+','-','@') { "'" + $rec.ResourceGroup } else { $rec.ResourceGroup }
                        Category         = if ($rec.Category -is [string] -and $rec.Category.Length -gt 0 -and $rec.Category[0] -in '=','+','-','@') { "'" + $rec.Category } else { $rec.Category }
                        Impact           = if ($rec.Impact -is [string] -and $rec.Impact.Length -gt 0 -and $rec.Impact[0] -in '=','+','-','@') { "'" + $rec.Impact } else { $rec.Impact }
                        Problem          = if ($rec.Problem -is [string] -and $rec.Problem.Length -gt 0 -and $rec.Problem[0] -in '=','+','-','@') { "'" + $rec.Problem } else { $rec.Problem }
                        Description      = if ($rec.Description -is [string] -and $rec.Description.Length -gt 0 -and $rec.Description[0] -in '=','+','-','@') { "'" + $rec.Description } else { $rec.Description }
                        LastUpdated      = if ($rec.LastUpdated -is [string] -and $rec.LastUpdated.Length -gt 0 -and $rec.LastUpdated[0] -in '=','+','-','@') { "'" + $rec.LastUpdated } else { $rec.LastUpdated }
                        IsRetirement     = if ($rec.IsRetirement -is [string] -and $rec.IsRetirement.Length -gt 0 -and $rec.IsRetirement[0] -in '=','+','-','@') { "'" + $rec.IsRetirement } else { $rec.IsRetirement }
                        RecommendationId = if ($rec.RecommendationId -is [string] -and $rec.RecommendationId.Length -gt 0 -and $rec.RecommendationId[0] -in '=','+','-','@') { "'" + $rec.RecommendationId } else { $rec.RecommendationId }
                        LearnMoreLink    = if ($rec.LearnMoreLink -is [string] -and $rec.LearnMoreLink.Length -gt 0 -and $rec.LearnMoreLink[0] -in '=','+','-','@') { "'" + $rec.LearnMoreLink } else { $rec.LearnMoreLink }
                        ResourceLink     = if ($rec.ResourceLink -is [string] -and $rec.ResourceLink.Length -gt 0 -and $rec.ResourceLink[0] -in '=','+','-','@') { "'" + $rec.ResourceLink } else { $rec.ResourceLink }
                        Solution         = if ($rec.Solution -is [string] -and $rec.Solution.Length -gt 0 -and $rec.Solution[0] -in '=','+','-','@') { "'" + $rec.Solution } else { $rec.Solution }
                    }
                }
                $safeRecs | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
            }
            "JSON" {
                $transformedRecs | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8
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
                
                # PowerShell 5.1 compatible UTC time (Get-Date -AsUTC is PS 7+ only)
                $generatedTime = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
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
                    <th>Description</th>
                    <th>Resource Group</th>
                    <th>Subscription ID</th>
                    <th>Resource Link</th>
                    <th>Learn More</th>
                </tr>
            </thead>
            <tbody>
"@

                # Add table rows - collect in array for better performance
                $tableRows = foreach ($rec in $transformedRecs) {
                    # HTML encode all user-provided data to prevent XSS
                    $encodedResourceName = ConvertTo-HtmlEncoded $rec.ResourceName
                    $encodedResourceType = ConvertTo-HtmlEncoded $rec.ResourceType
                    $encodedResourceGroup = ConvertTo-HtmlEncoded $rec.ResourceGroup
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
                    <td>$encodedResourceGroup</td>
                    <td><span class="recommendation-id">$encodedSubscriptionId</span></td>
                    <td>$encodedResourceLink</td>
                    <td>$encodedLearnMoreLink</td>
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
            <p>Generated by AzRetirementMonitor | Azure Service Retirement Monitoring Tool<br>
            <a href="https://github.com/cocallaw/AzRetirementMonitor" target="_blank" rel="noopener noreferrer">View on GitHub</a></p>
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