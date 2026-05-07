# Merge Pull Request GitHub Action

This GitHub Action merges a pull request using the GitHub REST API.  
It is designed to be simple, composable, and independent of the local git state.

## Features

- Merges a pull request in your repository using the REST API (no dependencies on local git or CLI).
- Supports merge, squash, and rebase strategies.
- Allows you to specify a custom commit title for the merge commit.
- Fully supports GitHub Organizations and user-owned repositories.
- Outputs the merge result and error message (if any) for use in subsequent workflow steps.
- Designed for secure automation with the minimal required token permissions.

## Inputs

| Name                   | Description                                                                                    | Required | Default |
|------------------------|------------------------------------------------------------------------------------------------|----------|---------|
| `pr-number`            | The number of the pull request to merge                                                        | Yes      |         |
| `repo-name`            | The name of the repository                                                                     | Yes      |         |
| `org-name`             | The name of the GitHub organization                                                            | Yes      |         |
| `merge-type`           | The type of merge to perform: `merge`, `squash`, or `rebase`                                  | Yes      |         |
| `merge-title-message`  | The commit title to use for the merge commit                                                   | Yes      |         |
| `token`                | GitHub token with access to pull requests                                                      | Yes      |         |

## Outputs

| Name            | Description                                           |
|-----------------|------------------------------------------------------|
| `result`        | Result of the merge attempt (`success` or `failure`) |
| `error-message` | Error message if the merge failed                    |

## Usage

Create a workflow file in your repository (e.g., `.github/workflows/merge-pr.yml`).  
**Ensure you pass all required inputs and use a valid token with PR write access.**

### Example Workflow

```yaml
name: Merge Pull Request
on:
  workflow_dispatch:

jobs:
  merge-pull-request:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: Merge Pull Request via API
        id: merge-pr
        uses: lee-lott-actions/merge-pull-request@v1
        with:
          pr-number: '101'
          repo-name: ${{ github.event.repository.name }}
          org-name: ${{ github.repository_owner }}
          merge-type: 'merge' # or 'squash' or 'rebase'
          merge-title-message: 'chore: auto-merge PR #101'
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Output Merge Result
        run: |
          echo "Merge Result: ${{ steps.merge-pr.outputs.result }}"
          echo "Error Message: ${{ steps.merge-pr.outputs['error-message'] }}"
```
