# Open Pull Requests Across Repositories GitHub Action
*by Kyama Games*

## Description

This GitHub Action is designed to open pull requests in another repository while tracking origin source folders. It supports multiple folders and provides various customization options.

## Inputs

- **destination-repository (required):** Destination repository.
- **source-folders (required):** Comma-separated source folders.
- **destination-folders (optional):** Comma-separated destination folders.
- **destination-head-branch (required):** The branch to create to push the changes.
- **pr-title (required):** The PR title which will be defined in the PR.
- **commit-message (required):** The commit message to be used.
- **destination-base-branch (optional, default: "main"):** The branch into which you want your PR merged.
- **pull-request-reviewers (optional):** Pull request reviewers.

## Example Action

```yaml
name: Open PR Across Repos

on:
  pull_request:
    branches:
      - main

jobs:
  open-pr:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Open PR
      uses: kyamalabs/action-open-pull-request-across-repositories@0.1.0
      with:
        destination-repository: 'owner/repo'
        source-folders: 'folder1,folder2'
        destination-folders: 'dest1,dest2'
        destination-head-branch: 'feature-branch'
        pr-title: 'Update from source folders'
        commit-message: 'Sync changes from source folders'
        destination-base-branch: 'main'
        pull-request-reviewers: 'username1,username2'
      env:
        API_TOKEN_GITHUB: ${{ secrets.API_TOKEN_GITHUB }}
```

## Important Note

Make sure to specify `API_TOKEN_GITHUB` as a secret in your repository. This token should have the following scopes: `'repo = Full control of private repositories', 'admin:org = read:org', and 'write:discussion = Read:discussion'`.
Note: The `API_TOKEN_GITHUB` is a personal access token with the required scopes. Keep it secure and do not expose it publicly.

## Acknowledgment

This action was inspired by [car-on-sale/action-pull-request-another-repo](https://github.com/car-on-sale/action-pull-request-another-repo/). We express our heartfelt gratitude for their pioneering work, without which the development of this action would not have been possible.

---
Feel free to customize the action according to your needs.
