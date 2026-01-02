$script:AccessToken = $null
$script:ApiVersion  = "2025-01-01"

$Public  = Get-ChildItem "$PSScriptRoot/Public/*.ps1" -Recurse
$Private = Get-ChildItem "$PSScriptRoot/Private/*.ps1" -Recurse

foreach ($file in @($Public + $Private)) {
    . $file.FullName
}

Export-ModuleMember -Function $Public.BaseName