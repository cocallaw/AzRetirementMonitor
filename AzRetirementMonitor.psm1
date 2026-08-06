# Store the token encrypted at rest in the module scope. Plaintext is created only
# transiently while building an HTTP Authorization header.
$script:AccessTokenSecureString = $null
$script:ApiVersion  = "2025-01-01"

$Public  = Get-ChildItem "$PSScriptRoot/Public/*.ps1" -Recurse
$Private = Get-ChildItem "$PSScriptRoot/Private/*.ps1" -Recurse

foreach ($file in @($Public + $Private)) {
    . $file.FullName
}

Export-ModuleMember -Function $Public.BaseName