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
if [ "$BRANCH_EXISTS" -ge 1 ];
then
    git checkout "$INPUT_DESTINATION_HEAD_BRANCH"
else
    git checkout -b "$INPUT_DESTINATION_HEAD_BRANCH"
fi

echo "Copying files"

[ "$(echo "$INPUT_SOURCE_FOLDERS" | tr -cd ',' | wc -c)" -ne "$(echo "$INPUT_DESTINATION_FOLDERS" | tr -cd ',' | wc -c)" ] && exit 1

IFS=','
last_destination_folder=""

while [ -n "$INPUT_SOURCE_FOLDERS" ] && [ -n "$INPUT_DESTINATION_FOLDERS" ]; do
  source_folder="${INPUT_SOURCE_FOLDERS%%,*}"
  INPUT_SOURCE_FOLDERS="${INPUT_SOURCE_FOLDERS#*,}"

  destination_folder="${INPUT_DESTINATION_FOLDERS%%,*}"
  INPUT_DESTINATION_FOLDERS="${INPUT_DESTINATION_FOLDERS#*,}"

  if [ "$last_destination_folder" = "$destination_folder" ]; then
      break
  fi

  last_destination_folder="$destination_folder"

  destination_path="$CLONE_DIR/$destination_folder"
  mkdir -p "$destination_path"

  rsync -a --delete "$HOME_DIR/$source_folder" "$CLONE_DIR/$destination_folder/"
done

cd "$CLONE_DIR"
git add .

if git status | grep -q "Changes to be committed"; then
  git commit --message "$INPUT_COMMIT_MESSAGE"

  if [ "$BRANCH_EXISTS" -ge 1 ]; then
    echo "Pushing git commit"
    git push -u --force origin HEAD:"$INPUT_DESTINATION_HEAD_BRANCH"

    echo "Updating pull request"
    CURRENT_BODY=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls?head=$INPUT_DESTINATION_HEAD_BRANCH&base=$INPUT_DESTINATION_BASE_BRANCH" \
      | jq -r '.[0].body')

    gh pr edit "$INPUT_DESTINATION_HEAD_BRANCH" -b "$CURRENT_BODY & https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
  else
    echo "Pushing git commit"
    git push -u --force origin HEAD:"$INPUT_DESTINATION_HEAD_BRANCH"

    echo "Creating a pull request"
    if [ -n "$INPUT_PULL_REQUEST_REVIEWERS" ]; then
      gh pr create -t "$INPUT_PR_TITLE" \
                   -b "https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA" \
                   -B "$INPUT_DESTINATION_BASE_BRANCH" \
                   -H "$INPUT_DESTINATION_HEAD_BRANCH" \
                   -r "$INPUT_PULL_REQUEST_REVIEWERS"
    else
      gh pr create -t "$INPUT_PR_TITLE" \
                   -b "https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA" \
                   -B "$INPUT_DESTINATION_BASE_BRANCH" \
                   -H "$INPUT_DESTINATION_HEAD_BRANCH"
    fi
  fi
else
  echo "No changes detected"
fi
