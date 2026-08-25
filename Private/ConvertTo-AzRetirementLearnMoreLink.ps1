function ConvertTo-AzRetirementLearnMoreLink {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$LearnMoreLink
    )

    if ([string]::IsNullOrWhiteSpace($LearnMoreLink)) {
        return $null
    }

    return $LearnMoreLink
}
