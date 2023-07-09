#!/usr/bin/env bash

# Some env variables
BRANCH="main"
REPO_URL="github.com/gofiber/docs.git"
AUTHOR_EMAIL="github-actions[bot]@users.noreply.github.com"
AUTHOR_USERNAME="github-actions[bot]"
DOCUSAURUS_CMD="docs:version:contrib"
VERSION_FILE="contrib_versions.json"
REPO_DIR="contrib"
COMMIT_URL="https://github.com/gofiber/contrib"

# Set commit author
git config --global user.email "${AUTHOR_EMAIL}"
git config --global user.name "${AUTHOR_USERNAME}"

git clone https://${TOKEN}@${REPO_URL} fiber-docs

# Handle push event
if [ "$EVENT" == "push" ]; then
  latest_commit=$(git rev-parse --short HEAD)

  for f in $(find . -type f -name "*.md" -not -path "./fiber-docs/*"); do
    log_output=$(git log --oneline "${BRANCH}" HEAD~1..HEAD --name-status -- "${f}")

    if [[ $log_output != "" || ! -f "fiber-docs/docs/${REPO_DIR}/$f" ]]; then
      mkdir -p fiber-docs/docs/${REPO_DIR}/$(dirname $f)
      cp "${f}" fiber-docs/docs/${REPO_DIR}/$f
    fi
  done

  commit_msg="Add docs from ${COMMIT_URL}/commit/${latest_commit}"

# Handle release event
elif [ "$EVENT" == "release" ]; then
  # Extract package name from tag
  package_name="${TAG_NAME%/*}"
  major_version="${TAG_NAME#*/}"
  major_version="${major_version%%.*}"

  # Form new version name
  new_version="${package_name}_v${major_version}.x.x"

  cd fiber-docs/ || return

  # Check if contrib_versions.json exists and modify it if required
  if [[ -f $VERSION_FILE ]]; then
    jq --arg new_version "$new_version" 'del(.[] | select(. == $new_version))' $VERSION_FILE > temp.json && mv temp.json $VERSION_FILE
  fi

  # Run docusaurus versioning command
  npm run docusaurus -- $DOCUSAURUS_CMD $new_version

  commit_msg="Sync docs for release ${COMMIT_URL}/releases/tag/${TAG_NAME}"
fi

# Push changes
cd fiber-docs/ || return
git add .
git commit -m "$commit_msg"
git push https://${TOKEN}@${REPO_URL}