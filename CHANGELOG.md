# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `OutputPath` validation in `Export-AzRetirementReport` to prevent path traversal (#37)
- Environment protection gate on publish workflow (#39)
- Retry with exponential backoff for ARM API throttling in `Invoke-AzPagedRequest` (#27)
- `-Stream` switch on `Get-AzRetirementRecommendation` for pipeline streaming (#30)
- Token Storage Considerations section in SECURITY.md (#25)
- `.EXAMPLE`, `.OUTPUTS`, `.LINK` help sections for `Get-AzRetirementMetadataItem` (#43)
- NextLink origin validation in `Invoke-AzPagedRequest` to prevent token forwarding to untrusted hosts (#24)

### Changed
- `Export-AzRetirementReport` uses `List[object]` instead of array concatenation for O(1) appends (#29)
- ExtendedProperty JSON is now parsed once and cached during subcategory filtering (#28)
- README and help text accurately describe token clearing behavior (#25, #41)

## [2.0.0] - 2026-03-19

### Added
- Az.Advisor PowerShell module as the default recommendation source
- `-UseAPI` switch on `Get-AzRetirementRecommendation` for REST API mode
- `-UsingAPI` required switch on `Connect-AzRetirementMonitor` to confirm API intent
- PowerShell 5.1 Desktop compatibility
- `Export-AzRetirementReport` with CSV, JSON, and HTML format support
- CSV formula injection sanitization
- HTML report with professional styling and XSS protection

### Changed
- **Breaking:** Default behavior now uses Az.Advisor module instead of REST API
- **Breaking:** `Connect-AzRetirementMonitor` now requires `-UsingAPI` switch
- Az.Advisor module is recommended and checked at runtime

## [1.2.1] - 2026-02-21

### Fixed
- Handle `SecureString` token from Az.Accounts 5.0+ (`Get-AzAccessToken` change)
- Improved test coverage for SecureString token handling

## [1.2.0] - 2026-02-19

### Added
- JWT audience validation to restrict tokens to `https://management.azure.com` scope
- `Disconnect-AzRetirementMonitor` function to clear the stored access token
- RBAC security documentation for token scope restriction

## [1.1.0] - 2026-02-06

### Added
- JWT token expiration validation before API calls
- HTML export format with professional styling and formatted timestamps
- Impact level explanation in README and HTML report
- Resource type, resource group, and resource portal links in HTML report

### Fixed
- XSS vulnerability in HTML report catch block
- HTML encoding applied throughout report generation

## [1.0.1] - 2026-01-28

### Changed
- Updated module description in manifest
- Added metadata to module manifest
- Added staging step before publishing

## [1.0.0] - 2026-01-27

### Added
- Initial release
- `Connect-AzRetirementMonitor` for Azure CLI and Az.Accounts authentication
- `Get-AzRetirementRecommendation` for retrieving retirement recommendations via REST API
- `Get-AzRetirementMetadataItem` for retrieving Advisor metadata
- `Export-AzRetirementReport` for CSV and JSON export
- Pagination support for Azure REST API responses

[Unreleased]: https://github.com/cocallaw/AzRetirementMonitor/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/cocallaw/AzRetirementMonitor/compare/v1.2.1...v2.0.0
[1.2.1]: https://github.com/cocallaw/AzRetirementMonitor/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/cocallaw/AzRetirementMonitor/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/cocallaw/AzRetirementMonitor/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/cocallaw/AzRetirementMonitor/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/cocallaw/AzRetirementMonitor/releases/tag/v1.0.0
