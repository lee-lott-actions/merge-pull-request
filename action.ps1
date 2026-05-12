function Merge-Pull-Request {
  param(
    [string]$RepoName,
    [string]$OrgName,
    [string]$PrNumber,
    [ValidateSet("merge", "squash", "rebase")]
    [string]$MergeType,
    [string]$MergeTitleMessage,
    [string]$Token
  )
  
  # Validate required inputs
  if ([string]::IsNullOrEmpty($RepoName) -or 
      [string]::IsNullOrEmpty($OrgName) -or 
      [string]::IsNullOrEmpty($PrNumber) -or 
      [string]::IsNullOrEmpty($MergeType) -or 
      [string]::IsNullOrEmpty($MergeTitleMessage) -or
      [string]::IsNullOrEmpty($Token)) 
  {
    Write-Output "Error: Missing required parameters"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: RepoName, OrgName, PrNumber, MergeType, MergeTitleMessage, and Token must be provided."
    Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
    return
  }
  
  $githubApiUrl = $env:MOCK_API
  if (-not $githubApiUrl) { $githubApiUrl = "https://api.github.com" }  
  $uri = "$githubApiUrl/repos/$OrgName/$RepoName/pulls/$PrNumber/merge"

  $headers = @{
      Authorization = "Bearer $Token"
      Accept = "application/vnd.github+json"
      "X-GitHub-Api-Version" = "2026-03-10"
      "Content-Type" = "application/json"      
  }
  
  $body = @{
      commit_title = $MergeTitleMessage
      merge_method = "$MergeType"
  } | ConvertTo-Json
  
  try {    
    Write-Host "Merging Pull Request #$PrNumber..."
    $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method PUT -Body $body -SkipHttpErrorCheck

   if ($response.StatusCode -eq 200) {
      Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
      Write-Host "Pull Request #$PrNumber in repository $RepoName merged with merge type $MergeType. Status: $($response.StatusCode)"
    } else {
      $errorMsg = "Error: Failed to merge pull request. Status: $($response.StatusCode)."
      Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
      Add-Content -Path $env:GITHUB_OUTPUT -vALUE "error-message=$errorMsg"
      Write-Host $errorMsg
    }      
  } catch {
    $errorMsg = "Error: Failed to merge pull request. Exception: $($_.Exception.Message)"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
    Write-Host $errorMsg
  }
}
