#!/bin/sh -l

set -e
set -x

required_params="
  INPUT_DESTINATION_REPOSITORY
  INPUT_SOURCE_FOLDERS
  INPUT_DESTINATION_FOLDERS
  INPUT_DESTINATION_HEAD_BRANCH
  INPUT_PR_TITLE
  INPUT_COMMIT_MESSAGE
  INPUT_DESTINATION_BASE_BRANCH
"

for param in $required_params; do
  eval "value=\$$param"
  if [ -z "$value" ]; then
    echo "$param must be defined"
    exit 1
  fi
done

if [ -z "$INPUT_PULL_REQUEST_REVIEWERS" ]
then
  PULL_REQUEST_REVIEWERS=$INPUT_PULL_REQUEST_REVIEWERS
else
  PULL_REQUEST_REVIEWERS='-r '$INPUT_PULL_REQUEST_REVIEWERS
fi

HOME_DIR=$PWD
CLONE_DIR=$(mktemp -d)

echo "Setting git variables"
git config --global user.email "$GITHUB_ACTOR@users.noreply.github.com"
git config --global user.name "$GITHUB_ACTOR"

echo "Cloning destination git repository"
git config --global --add safe.directory /github/workspace
git clone "https://$API_TOKEN_GITHUB@github.com/$INPUT_DESTINATION_REPOSITORY.git" "$CLONE_DIR"

BRANCH_EXISTS=$(git show-ref "$INPUT_DESTINATION_HEAD_BRANCH" | wc -l)

echo "Checking if branch already exists"
git fetch -a
if [ "$BRANCH_EXISTS" = 1 ];
then
    git checkout "$INPUT_DESTINATION_HEAD_BRANCH"
else
    git checkout -b "$INPUT_DESTINATION_HEAD_BRANCH"
fi

echo "Copying files"

IFS=',' read -ra source_folders <<< "$INPUT_SOURCE_FOLDERS"
IFS=',' read -ra destination_folders <<< "$INPUT_DESTINATION_FOLDERS"

if [ "${#source_folders[@]}" -ne "${#destination_folders[@]}" ]; then
    echo "Number of source and destination folders must match"
    exit 1
fi

for ((i=0; i<${#source_folders[@]}; i++)); do
    source_folder="${source_folders[i]}"
    destination_folder="${destination_folders[i]}"

    rsync -a --delete "$HOME_DIR/$source_folder" "$CLONE_DIR/$destination_folder/"
done

git add .

if git status | grep -q "Changes to be committed"; then
  git commit --message "$INPUT_COMMIT_MESSAGE"

  if [ "$BRANCH_EXISTS" -eq 1 ]; then
    echo "Pushing git commit"
    git push -u origin HEAD:"$INPUT_DESTINATION_HEAD_BRANCH"

    echo "Updating pull request"
    CURRENT_BODY=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls?head=$INPUT_DESTINATION_HEAD_BRANCH&base=$INPUT_DESTINATION_BASE_BRANCH" \
      | jq -r '.[0].body')

    gh pr edit "$INPUT_DESTINATION_HEAD_BRANCH" -b "$CURRENT_BODY & https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
  else
    echo "Pushing git commit"
    git push -u origin HEAD:"$INPUT_DESTINATION_HEAD_BRANCH"

    echo "Creating a pull request"
    gh pr create -t "$INPUT_PR_TITLE" \
                 -b "https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA" \
                 -B "$INPUT_DESTINATION_BASE_BRANCH" \
                 -H "$INPUT_DESTINATION_HEAD_BRANCH" \
                 "$PULL_REQUEST_REVIEWERS"
  fi
else
  echo "No changes detected"
fi
