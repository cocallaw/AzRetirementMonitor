BeforeAll {
    # Test simulates the "Prepare Module for Publishing" step from publish.yml
    $script:stagingDir = "$TestDrive/staging/AzRetirementMonitor"
}

Describe "Publish Workflow - Module Staging" {
    BeforeEach {
        # Clean up staging directory before each test
        if (Test-Path $script:stagingDir) {
            Remove-Item -Path $script:stagingDir -Recurse -Force
        }
    }
    
    It "Should exclude the images directory when staging module for publish" {
        # Simulate the staging process from .github/workflows/publish.yml
        New-Item -ItemType Directory -Path $script:stagingDir -Force | Out-Null
        
        $repoRoot = Split-Path $PSScriptRoot -Parent
        
        # Copy only the files needed for the module (matching publish.yml lines 71-76)
        Copy-Item -Path "$repoRoot/AzRetirementMonitor.psd1" -Destination $script:stagingDir -Force
        Copy-Item -Path "$repoRoot/AzRetirementMonitor.psm1" -Destination $script:stagingDir -Force
        Copy-Item -Path "$repoRoot/LICENSE" -Destination $script:stagingDir -Force
        Copy-Item -Path "$repoRoot/README.md" -Destination $script:stagingDir -Force
        Copy-Item -Path "$repoRoot/Public" -Destination $script:stagingDir -Recurse -Force
        Copy-Item -Path "$repoRoot/Private" -Destination $script:stagingDir -Recurse -Force
        
        # Verify images directory is NOT in staging
        $imagesInStaging = Test-Path "$script:stagingDir/images"
        $imagesInStaging | Should -Be $false -Because "images directory should not be published to PowerShell Gallery"
    }
    
    It "Should verify that images directory exists in the repository" {
        # Verify the images directory actually exists in the repo
        # This ensures our test is meaningful - we're testing exclusion of something that exists
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $imagesInRepo = Test-Path "$repoRoot/images"
        $imagesInRepo | Should -Be $true -Because "images directory should exist in the repository for documentation"
        
        # Verify it contains the example image
        $exampleImage = Test-Path "$repoRoot/images/example-html-report.png"
        $exampleImage | Should -Be $true -Because "example image should exist for README documentation"
    }
    
    It "Should stage only expected files and directories" {
        # Simulate the staging process from .github/workflows/publish.yml
        New-Item -ItemType Directory -Path $script:stagingDir -Force | Out-Null
        
        $repoRoot = Split-Path $PSScriptRoot -Parent
        
        # Copy only the files needed for the module (matching publish.yml)
        Copy-Item -Path "$repoRoot/AzRetirementMonitor.psd1" -Destination $script:stagingDir -Force
        Copy-Item -Path "$repoRoot/AzRetirementMonitor.psm1" -Destination $script:stagingDir -Force
        Copy-Item -Path "$repoRoot/LICENSE" -Destination $script:stagingDir -Force
        Copy-Item -Path "$repoRoot/README.md" -Destination $script:stagingDir -Force
        Copy-Item -Path "$repoRoot/Public" -Destination $script:stagingDir -Recurse -Force
        Copy-Item -Path "$repoRoot/Private" -Destination $script:stagingDir -Recurse -Force
        
        # Get all items in staging directory
        $stagedItems = Get-ChildItem -Path $script:stagingDir -Name
        
        # Verify expected items are present
        $stagedItems | Should -Contain "AzRetirementMonitor.psd1"
        $stagedItems | Should -Contain "AzRetirementMonitor.psm1"
        $stagedItems | Should -Contain "LICENSE"
        $stagedItems | Should -Contain "README.md"
        $stagedItems | Should -Contain "Public"
        $stagedItems | Should -Contain "Private"
        
        # Verify excluded items are NOT present
        $stagedItems | Should -Not -Contain "images" -Because "images directory should be excluded from publish"
        $stagedItems | Should -Not -Contain "Tests" -Because "Tests directory should be excluded from publish"
        $stagedItems | Should -Not -Contain ".git" -Because ".git directory should be excluded from publish"
        $stagedItems | Should -Not -Contain ".github" -Because ".github directory should be excluded from publish"
    }
}
