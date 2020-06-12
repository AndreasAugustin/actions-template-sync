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
source sync_template.sh
