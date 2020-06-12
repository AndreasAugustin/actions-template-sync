#! /usr/bin/env bash
set -e

[ -z "${GITHUB_TOKEN}" ] && {
    echo "Missing input 'github_token: \${{ secrets.GITHUB_TOKEN }}'.";
    exit 1;
};

if [[ -z "${SOURCE_REPO_PATH}" ]]; then
  echo "Missing input 'source_repo_path: \${{ input.source_repo_path }}'.;"
  exit 1
fi

SOURCE_REPO="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${SOURCE_REPO_PATH}"

echo "set git global configuration"
git config --global user.email "github-action@actions-template-sync.noreply.github.com@"
git config --global user.name "${GITHUB_ACTOR}"

source sync_template.sh
