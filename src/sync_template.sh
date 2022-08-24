#! /usr/bin/env bash
set -e
# set -u
set -x

if [[ -z "${SOURCE_REPO}" ]]; then
  echo "::error::Missing env variable 'SOURCE_REPO'" >&2;
  exit 1;
fi

if [[ -z "${UPSTREAM_BRANCH}" ]]; then
  echo "::error::Missing env variable 'UPSTREAM_BRANCH'" >&2;
  exit 1;
fi

if [[ -z "${PR_LABELS}" ]]; then
  echo "::error::Missing env variable 'PR_LABELS'" >&2;
  exit 1;
fi

if ! [ -x "$(command -v gh)" ]; then
  echo "::error::github-cli gh is not installed. 'https://github.com/cli/cli'" >&2;
  exit 1;
fi

if [[ -n "${SRC_SSH_PRIVATEKEY_ABS_PATH}" ]]; then
  echo "::debug:: using ssh private key for private source repository"
  export GIT_SSH_COMMAND="ssh -i ${SRC_SSH_PRIVATEKEY_ABS_PATH}"
fi

TEMPLATE_VERSION_FILE_NAME=".templateversionrc"
TEMPLATE_SYNC_IGNORE_FILE_NAME=".templatesyncignore"
TEMPLATE_REMOTE_GIT_HASH=$(git ls-remote "${SOURCE_REPO}" HEAD | awk '{print $1}')
NEW_TEMPLATE_GIT_HASH=$(git rev-parse --short "${TEMPLATE_REMOTE_GIT_HASH}")
NEW_BRANCH="${PR_BRANCH_NAME_PREFIX}_${NEW_TEMPLATE_GIT_HASH}"

echo "::group::Check new changes"
echo "::debug::new Git HASH ${NEW_TEMPLATE_GIT_HASH}"
if [ -r ${TEMPLATE_VERSION_FILE_NAME} ]
then
  CURRENT_TEMPLATE_GIT_HASH=$(cat ${TEMPLATE_VERSION_FILE_NAME})
  echo "::debug::Current git hash ${CURRENT_TEMPLATE_GIT_HASH}"
fi

if [ "${NEW_TEMPLATE_GIT_HASH}" == "${CURRENT_TEMPLATE_GIT_HASH}" ]
then
  echo "::warn::repository is up to date"
  exit 0
fi
echo "::endgroup::"

echo "::group::Pull template"
echo "::debug::create new branch from default branch with name ${NEW_BRANCH}"
git checkout -b "${NEW_BRANCH}"
echo "::debug::pull changes from template"
git pull "${SOURCE_REPO}" --allow-unrelated-histories --squash --strategy=recursive -X theirs
echo "::endgroup::"

echo "::group::persist template version"
echo "write new template version file"
echo "${NEW_TEMPLATE_GIT_HASH}" > ${TEMPLATE_VERSION_FILE_NAME}
echo "::debug::wrote new template version file with content $(cat ${TEMPLATE_VERSION_FILE_NAME})"
echo "::endgroup::"

echo "::group::commit and push changes"
git add .

if [ -r ${TEMPLATE_SYNC_IGNORE_FILE_NAME} ]
then
  echo "::debug::unstage files from template sync ignore"
  git reset --pathspec-from-file="${TEMPLATE_SYNC_IGNORE_FILE_NAME}"

  echo "::debug::clean untracked files"
  git clean -df

  echo "::debug::discard all unstaged changes"
  git checkout -- .
fi

git commit -m "chore(template): merge template changes :up:"

echo "::debug::push changes"
git push --set-upstream origin "${NEW_BRANCH}"
echo "::endgroup::"

echo "::group::create pull request"
gh pr create \
  --title ${PR_TITLE} \
  --body "Merge ${SOURCE_REPO_PATH} ${NEW_TEMPLATE_GIT_HASH}" \
  -B "${UPSTREAM_BRANCH}" \
  -l "${PR_LABELS}"
echo "::endgroup::"
