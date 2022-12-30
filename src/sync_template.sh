#! /usr/bin/env bash

set -e
# set -u
set -x

# shellcheck source=src/sync_template.sh
source sync_common.sh

if [[ -z "${PR_COMMIT_MSG}" ]]; then
  err "Missing env variable 'PR_COMMIT_MSG'";
  exit 1;
fi

if [[ -z "${SOURCE_REPO}" ]]; then
  err "Missing env variable 'SOURCE_REPO'";
  exit 1;
fi

if [[ -z "${UPSTREAM_BRANCH}" ]]; then
  err "Missing env variable 'UPSTREAM_BRANCH'";
  exit 1;
fi

if ! [ -x "$(command -v gh)" ]; then
  err "github-cli gh is not installed. 'https://github.com/cli/cli'";
  exit 1;
fi

if [[ -n "${SRC_SSH_PRIVATEKEY_ABS_PATH}" ]]; then
  debug "using ssh private key for private source repository"
  export GIT_SSH_COMMAND="ssh -i ${SRC_SSH_PRIVATEKEY_ABS_PATH}"
fi

TEMPLATE_SYNC_IGNORE_FILE_PATH=".templatesyncignore"
TEMPLATE_REMOTE_GIT_HASH=$(git ls-remote "${SOURCE_REPO}" HEAD | awk '{print $1}')
NEW_TEMPLATE_GIT_HASH=$(git rev-parse --short "${TEMPLATE_REMOTE_GIT_HASH}")
NEW_BRANCH="${PR_BRANCH_NAME_PREFIX}_${NEW_TEMPLATE_GIT_HASH}"
debug "new Git HASH ${NEW_TEMPLATE_GIT_HASH}"

echo "::group::Check new changes"

git cat-file -e "${TEMPLATE_REMOTE_GIT_HASH}" || COMMIT_NOT_IN_HIST=true
if [ "$COMMIT_NOT_IN_HIST" != true ] ; then
    warn "repository is up to date!"
		exit 0
fi

echo "::endgroup::"

echo "::group::Pull template"
debug "create new branch from default branch with name ${NEW_BRANCH}"
git checkout -b "${NEW_BRANCH}"
debug "pull changes from template"
# TODO(anau) eventually make squash optional
git pull "${SOURCE_REPO}" --allow-unrelated-histories --squash --strategy=recursive -X theirs
echo "::endgroup::"

if [ -s "${TEMPLATE_SYNC_IGNORE_FILE_PATH}" ]; then
  echo "::group::restore ignore file"
	info "restore the ignore file"
  git reset "${TEMPLATE_SYNC_IGNORE_FILE_PATH}"
  git checkout -- "${TEMPLATE_SYNC_IGNORE_FILE_PATH}"
  echo "::endgroup::"
fi

echo "::group::commit changes"
git add .

# Check if the Ignore File exists inside .github folder or if it doesn't exist at all
if [[ -f ".github/${TEMPLATE_SYNC_IGNORE_FILE_PATH}" || ! -f "${TEMPLATE_SYNC_IGNORE_FILE_PATH}" ]]; then
  debug "using ignore file as in .github folder"
  TEMPLATE_SYNC_IGNORE_FILE_PATH=".github/${TEMPLATE_SYNC_IGNORE_FILE_PATH}"
fi
# we are checking the ignore file if it exists or is empty
# -s is true if the file contains whitespaces
if [ -s ${TEMPLATE_SYNC_IGNORE_FILE_PATH} ]; then
  debug "unstage files from template sync ignore"
  git reset --pathspec-from-file="${TEMPLATE_SYNC_IGNORE_FILE_PATH}"

  debug "clean untracked files"
  git clean -df

  debug "discard all unstaged changes"
  git checkout -- .
fi

git commit -m "${PR_COMMIT_MSG}"

echo "::endgroup::"

push_and_create_pr () {
  if [ "$IS_DRY_RUN" != "true" ]; then
		echo "::group::push changes and create PR"
    debug "push changes"
    git push --set-upstream origin "${NEW_BRANCH}"

    gh pr create \
      --title "${PR_TITLE}" \
      --body "Merge ${SOURCE_REPO_PATH} ${NEW_TEMPLATE_GIT_HASH}" \
      -B "${UPSTREAM_BRANCH}" \
      -l "${PR_LABELS}"
    echo "::endgroup::"
  else
    warn "dry_run option is set to off. Skipping push changes and skip create pr"
  fi
}

push_and_create_pr
