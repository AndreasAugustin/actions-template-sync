#! /usr/bin/env bash
set -e

if [[ -z "${SOURCE_REPO}" ]]; then
  echo "Error: Missing env variable 'SOURCE_REPO'" >&2;
  exit 1;
fi

# if ! [ -x "$(command -v gh)" ]; then
#   echo "Error: github-cli gh is not installed. 'https://github.com/cli/cli'" >&2;
#   exit 1;
# fi

if ! [ -x "$(command -v hub)" ]; then
  echo "Error: hub is not installed. 'https://github.com/github/hub'" >&2;
  exit 1;
fi

NEW_BRANCH="chore/template_sync"

echo "start sync"
echo "create new branch from default branch with name ${NEW_BRANCH}"
git checkout -b ${NEW_BRANCH}
echo "pull changes from template"
git pull "${SOURCE_REPO}" --allow-unrelated-histories --squash --strategy=recursive -X theirs
git add .
git commit -m "chore(template): merge template changes :up:"
echo "push changes"
git push --set-upstream origin "${NEW_BRANCH}"
echo "create pull request"
# Workaround for `hub` auth error https://github.com/github/hub/issues/2149#issuecomment-513214342
export GITHUB_USER="$GITHUB_ACTOR"
hub pull-request \
  -b master \
  -h $NEW_BRANCH \
  --no-edit
# gh pr create -B master -f -l chore
