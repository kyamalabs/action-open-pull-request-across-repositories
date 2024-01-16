# Open Pull Requests Across Repositories GitHub Action
*by Kyama Games*

## Description

This GitHub Action is designed to open pull requests in another repository while tracking origin source folders. It supports multiple folders and provides various customization options.

## Inputs

- **destination_repository (required):** Destination repository.
- **source_folders (required):** Comma-separated source folders.
- **destination_folders (optional):** Comma-separated destination folders.
- **destination_head_branch (required):** The branch to create to push the changes.
- **pr_title (required):** The PR title which will be defined in the PR.
- **commit_message (required):** The commit message to be used.
- **destination_base_branch (optional, default: "main"):** The branch into which you want your PR merged.
- **pull_request_reviewers (optional):** Pull request reviewers.

## Example Workflow

```yaml
name: Open PR Across Repos

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  update_shared_proto:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Open PR Across Repos
        uses: kyamalabs/action-open-pull-request-across-repositories@v0.1.23
        with:
          destination_repository: 'owner/repo'
          source_folders: 'folder1,folder2'
          destination_folders: 'dest1,dest2'
          destination_head_branch: 'feature-branch'
          pr_title: 'Update from source folders'
          commit_message: 'Sync changes from source folders'
          destination_base_branch: 'main'
          pull_request_reviewers: 'john_doe'
        env:
          GITHUB_TOKEN: ${{ secrets.CUSTOM_PAT }}
          API_TOKEN_GITHUB: ${{ secrets.CUSTOM_PAT }}
```

## Important Notes

- Make sure to specify `API_TOKEN_GITHUB` as a secret in your repository. This token should have the following scopes: `'repo = Full control of private repositories', 'admin:org = read:org', and 'write:discussion = Read:discussion'`.
Note: The `API_TOKEN_GITHUB` is a personal access token with the required scopes. Keep it secure and do not expose it publicly.
- The action automatically generates destination paths if they are absent, overwriting existing files in the specified locations.
- Subsequent workflow executions will perform a force push to the specified branch, leading to the replacement of previous content.

## Acknowledgment

This action was inspired by [car-on-sale/action-pull-request-another-repo](https://github.com/car-on-sale/action-pull-request-another-repo/). We express our heartfelt gratitude for their pioneering work, without which the development of this action would not have been possible.

---
Feel free to customize the action according to your needs.
