#! /usr/bin/env bash
set -e

if [[ -z "${SOURCE_REPO}" ]]; then
  echo "Error: Missing env variable 'SOURCE_REPO'" >&2;
  exit 1;
fi

if ! [ -x "$(command -v gh)" ]; then
  echo "Error: github-cli gh is not installed. 'https://github.com/cli/cli'" >&2;
  exit 1;
fi

NEW_BRANCH="chore/template_sync"

echo "start sync"
echo "create new branch from default branch with name ${NEW_BRANCH}"
git checkout -b ${NEW_BRANCH}
echo "pull changes from template"
git pull "${SOURCE_REPO}" --allow-unrelated-histories
git add .
git commit -m "chore(template): merge template changes :up:"
echo "push changes"
git push --set-upstream origin "${NEW_BRANCH}"
echo "create pull request"
gh pr create -b master -f -l chore
