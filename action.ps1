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
      "X-GitHub-Api-Version" = "2022-11-28"
      "User-Agent" = "pwsh-action"
  }
  
  $body = @{
      commit_title = $MergeTitleMessage
      merge_method = "$MergeType"
  } | ConvertTo-Json
  
  try {
      Write-Host "Merging Pull Request..."
      $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method PUT -Body $body
 
     if ($response.StatusCode -eq 200) {
          "result=success" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
          Write-Host "Pull Request #$PrNumber in repository $RepoName merged with merge type $MergeType. Status: $($response.StatusCode)"
      } else {
          "result=failure" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
          "error-message=Merge failed with status code $($response.StatusCode)." | Out-File -FilePath $env:GITHUB_OUTPUT -Append
          Write-Host "Merged failed with status code $($response.StatusCode)."
      }      
  } catch {
    "result=failure" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    "error-message=Merge threw an exception and failed." | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    Write-Error "Failed to merge pull request: $_"      
  }
}