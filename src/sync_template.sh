#! /usr/bin/env bash
set -e

if [[ -z "${SOURCE_REPO}" ]]; then
  echo "Error: Missing env variable 'SOURCE_REPO'" >&2;
  exit 1;
fi

if [[ -z "${UPSTREAM_BRANCH}" ]]; then
  echo "Error: Missing env variable 'UPSTREAM_BRANCH'" >&2;
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

TEMPLATE_VERSION_FILE_NAME=".templateversionrc"
TEMPLATE_REMOTE_GIT_HASH=$(git ls-remote "${SOURCE_REPO}" HEAD | awk {'print $1}')
NEW_TEMPLATE_GIT_HASH=$(git rev-parse --short "${TEMPLATE_REMOTE_GIT_HASH}")
NEW_BRANCH="chore/template_sync_${NEW_TEMPLATE_GIT_HASH}"

echo "start sync"
echo "create new branch from default branch with name ${NEW_BRANCH}"
git checkout -b "${NEW_BRANCH}"
echo "pull changes from template"
git pull "${SOURCE_REPO}" --allow-unrelated-histories --squash --strategy=recursive -X theirs

echo "new Git HASH ${NEW_TEMPLATE_GIT_HASH}"
if [ -r ${TEMPLATE_VERSION_FILE_NAME} ]
then
  CURRENT_TEMPLATE_GIT_HASH=$(cat ${TEMPLATE_VERSION_FILE_NAME})
  echo "Current git hash ${CURRENT_TEMPLATE_GIT_HASH}"
fi

if [ "${NEW_TEMPLATE_GIT_HASH}" == "${CURRENT_TEMPLATE_GIT_HASH}" ]
then
  echo "repository is up to date"
  exit 0
fi

echo "write new template version file"
echo "${NEW_TEMPLATE_GIT_HASH}" > ${TEMPLATE_VERSION_FILE_NAME}
echo "wrote new template version file with content $(cat ${TEMPLATE_VERSION_FILE_NAME})"

git add .
git commit -m "chore(template): merge template changes :up:"

echo "push changes"
git push --set-upstream origin "${NEW_BRANCH}"
echo "create pull request"

# # Workaround for `hub` auth error https://github.com/github/hub/issues/2149#issuecomment-513214342
export GITHUB_USER="$GITHUB_ACTOR"
hub pull-request \
  -b "${UPSTREAM_BRANCH}" \
  -h "${NEW_BRANCH}" \
  --no-edit
# gh pr create -B master -f -l chore
