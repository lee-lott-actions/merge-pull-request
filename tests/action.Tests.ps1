# Dummy values for required parameters
$script:OrgName    = "my-org"
$script:RepoName   = "my-repo"
$script:PrNumber   = "101"
$script:MergeType  = "merge"
$script:MergeTitleMessage = "Unit test merge commit title"
$script:Token      = "dummy-token"
$script:ApiUrl     = "https://api.mytests.com"

Describe "Merge-Pull-Request" {
    BeforeAll {
        . "$PSScriptRoot/../action.ps1"
    }

    BeforeEach {
        # Clean up GITHUB_OUTPUT for each test
        $env:GITHUB_OUTPUT = "$PSScriptRoot/github_output.temp"
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
    }
    
    AfterAll {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
    }
    
    It "merges a PR and writes result=success to output" {
        # Arrange
        Mock Invoke-WebRequest {
            # Simulate a web response with a status code
            [PSCustomObject]@{
                StatusCode = 200
                Content = '{"merged":true,"message":"Pull Request successfully merged"}'
            }
        }

        # Set mock API endpoint
        $env:MOCK_API = $ApiUrl

        # Act
        Merge-Pull-Request `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -MergeType $MergeType `
            -MergeTitleMessage $MergeTitleMessage `
            -Token $Token

        # Assert
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=success"
    }

    It "writes result=failure and error-message to output for non-200 response" {
        # Arrange
        Mock Invoke-WebRequest {
            [PSCustomObject]@{
                StatusCode = 405
                Content = '{"message":"Method Not Allowed"}'
            }
        }
        $env:MOCK_API = $ApiUrl

        # Act
        Merge-Pull-Request `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -MergeType $MergeType `
            -MergeTitleMessage $MergeTitleMessage `
            -Token $Token

        # Assert
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Merge failed with status code 405."
    }

    It "writes result=failure and error-message to output on web error" {
        Mock Invoke-WebRequest { throw "API Error" }
        $env:MOCK_API = $ApiUrl

        try {
            Merge-Pull-Request `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -MergeType $MergeType `
                -MergeTitleMessage $MergeTitleMessage `
                -Token $Token
        } catch {}

        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Merge threw an exception and failed."
    }

    It "throws if PrStatus is empty" {
        { Set-Pull-Request-Review-Status `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -PrStatus "" `
            -PrMessage $PrMessage `
            -Token $Token
        } | Should -Throw
    }

    It "throws if MergeType is not valid" {
        { 
            Merge-Pull-Request `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -MergeType "INVALID_TYPE" `
                -MergeTitleMessage $MergeTitleMessage `
                -Token $Token
        } | Should -Throw
    }

    It "writes result=failure for empty RepoName" {
        Merge-Pull-Request `
            -RepoName "" `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -MergeType $MergeType `
            -MergeTitleMessage $MergeTitleMessage `
            -Token $Token
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, MergeType, MergeTitleMessage, and Token must be provided."
    }
    
    It "writes result=failure for empty OrgName" {
        Merge-Pull-Request `
            -RepoName $RepoName `
            -OrgName "" `
            -PrNumber $PrNumber `
            -MergeType $MergeType `
            -MergeTitleMessage $MergeTitleMessage `
            -Token $Token
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, MergeType, MergeTitleMessage, and Token must be provided."
    }
    
    It "writes result=failure for empty PrNumber" {
        Merge-Pull-Request `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber "" `
            -MergeType $MergeType `
            -MergeTitleMessage $MergeTitleMessage `
            -Token $Token
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, MergeType, MergeTitleMessage, and Token must be provided."
    }
    
    It "throws if MergeType is empty" {
        { 
            Merge-Pull-Request `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -MergeType "" `
                -MergeTitleMessage $MergeTitleMessage `
                -Token $Token
        } | Should -Throw
    }
    
    It "writes result=failure for empty MergeTitleMessage" {
        Merge-Pull-Request `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -MergeType $MergeType `
            -MergeTitleMessage "" `
            -Token $Token
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, MergeType, MergeTitleMessage, and Token must be provided."
    }
    
    It "writes result=failure for empty Token" {
        Merge-Pull-Request `
            -RepoName $RepoName `
            -OrgName $OrgName `
            -PrNumber $PrNumber `
            -MergeType $MergeType `
            -MergeTitleMessage $MergeTitleMessage `
            -Token ""
    
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: RepoName, OrgName, PrNumber, MergeType, MergeTitleMessage, and Token must be provided."
    }
}