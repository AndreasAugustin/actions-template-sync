#! /usr/bin/env bash
set -e

[ -z "${GITHUB_TOKEN}" ] && {
    echo "Missing input 'github_token: \${{ secrets.GITHUB_TOKEN }}'.";
    exit 1;
};

if [[ -z "${SOURCE_REPO}" ]]; then
  echo "Missing input 'source_repo: \${{ input.source_repo }}'.;"
  exit 1
fi

UPSTREAM_REPO="${SOURCE_REPO}"
SOURCE_BRANCH="master"
NEW_BRANCH="chore/template_sync"

echo "start sync"
git config --unset-all http."https://github.com/".extraheader
git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"
git remote add tmp_upstream "$UPSTREAM_REPO"
echo "fetching source repo ${UPSTREAM_REPO}"
git fetch tmp_upstream
git remote --verbose
echo "push to new branch ${NEW_BRANCH}"
git push origin "refs/remotes/tmp_upstream/${SOURCE_BRANCH}:refs/heads/${NEW_BRANCH}"
echo "cleanup"
git remote rm tmp_upstream
git remote --verbose
