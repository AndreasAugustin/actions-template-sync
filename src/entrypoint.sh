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

NEW_BRANCH="chore/template_sync"

echo "start sync"
echo "create new branch from default branch with name ${NEW_BRANCH}"
git checkout -b ${NEW_BRANCH}
echo "pull changes from template"
#git pull "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$SOURCE_REPO" --allow-unrelated-histories
git pull "${SOURCE_REPO}"
git add .
git commit -m "chore(template): merge template changes :up:"
echo "push changes"
git push --set-upstream origin "${NEW_BRANCH}"
echo "create pull request"
gh pr create -b master -f -l chore
