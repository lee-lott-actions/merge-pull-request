Describe "Merge-Pull-Request" {
    BeforeAll {
        $script:OrgName           = "my-org"
        $script:RepoName          = "my-repo"
        $script:PrNumber          = "101"
        $script:MergeType         = "merge"
        $script:MergeTitleMessage = "Unit test merge commit title"
        $script:Token             = "dummy-token"
        $script:MockApiUrl        = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }

    BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
    
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

    Context "Success Cases" {
        It "unit: Merge-Pull-Request succeeds with HTTP 200" {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{
                    StatusCode = 200
                    Content = '{"merged":true,"message":"Pull Request successfully merged"}'
                }
            }
    
             Merge-Pull-Request `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -MergeType $MergeType `
                -MergeTitleMessage $MergeTitleMessage `
                -Token $Token
    
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=success"
        }
    }

    Context "HTTP Failure Cases" {
        It "unit: Merge-Pull-Request fails with HTTP 405" {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{
                    StatusCode = 405
                    Content = '{"message":"Method Not Allowed"}'
                }
            }

            Merge-Pull-Request `
                -RepoName $RepoName `
                -OrgName $OrgName `
                -PrNumber $PrNumber `
                -MergeType $MergeType `
                -MergeTitleMessage $MergeTitleMessage `
                -Token $Token
    
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Error: Failed to merge pull request. Status: 405."
        }
    }

    Context "Parameter Validation Failure Cases" {
        It "unit: Merge-Pull-Request fails with empty RepoName" {
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

        It "unit: Merge-Pull-Request fails with empty OrgName" {
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

        It "unit: Merge-Pull-Request fails with empty PrNumber" {
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

        It "unit: Merge-Pull-Request throws exception if MergeType is empty" {
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

        It "unit: Merge-Pull-Request throws exception if MergeType is not valid" {
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
        
        It "unit: Merge-Pull-Request fails with empty MergeTitleMessage" {
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
        
        It "unit: Merge-Pull-Request fails with empty Token" {
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

    Context "Exception Failure Cases" {
        It "unit: Merge-Pull-Request fails with exception" {
            Mock Invoke-WebRequest { throw "API Error" }
    
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
            $output | Where-Object { $_ -match "^error-message=Error: Failed to merge pull request. Exception:" } |
				Should -Not -BeNullOrEmpty
        }
    }    
}
