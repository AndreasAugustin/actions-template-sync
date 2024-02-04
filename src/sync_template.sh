#!/usr/bin/env bash

set -e
# set -u
# set -x

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

if ! [ -x "$(command -v gh)" ]; then
  err "github-cli gh is not installed. 'https://github.com/cli/cli'";
  exit 1;
fi

if [[ -z "${UPSTREAM_BRANCH}" ]]; then
  UPSTREAM_BRANCH="$(git remote show origin | awk '/HEAD branch/ {print $NF}')"
  info "Missing env variable 'UPSTREAM_BRANCH' setting to remote default ${UPSTREAM_BRANCH}";
fi

if [[ -n "${SRC_SSH_PRIVATEKEY_ABS_PATH}" ]]; then
  debug "using ssh private key for private source repository"
  export GIT_SSH_COMMAND="ssh -i ${SRC_SSH_PRIVATEKEY_ABS_PATH}"
fi

GIT_REMOTE_PULL_PARAMS="${GIT_REMOTE_PULL_PARAMS:---allow-unrelated-histories --squash --strategy=recursive -X theirs}"

cmd_from_yml_file "install"

LOCAL_CURRENT_GIT_HASH=$(git rev-parse HEAD)

info "current git hash: ${LOCAL_CURRENT_GIT_HASH}"

TEMPLATE_SYNC_IGNORE_FILE_PATH=".templatesyncignore"
TEMPLATE_REMOTE_GIT_HASH=$(git ls-remote "${SOURCE_REPO}" HEAD | awk '{print $1}')
NEW_TEMPLATE_GIT_HASH=$(git rev-parse --short "${TEMPLATE_REMOTE_GIT_HASH}")
NEW_BRANCH="${PR_BRANCH_NAME_PREFIX}_${NEW_TEMPLATE_GIT_HASH}"
debug "new Git HASH ${NEW_TEMPLATE_GIT_HASH}"

echo "::group::Check new changes"

function check_branch_remote_existing() {
  git ls-remote --exit-code --heads origin "${NEW_BRANCH}" || BRANCH_DOES_NOT_EXIST=true

  if [[ "${BRANCH_DOES_NOT_EXIST}" != true ]]; then
    warn "Git branch '${NEW_BRANCH}' exists in the remote repository"
    exit 0
  fi
}

check_branch_remote_existing

git cat-file -e "${TEMPLATE_REMOTE_GIT_HASH}" || COMMIT_NOT_IN_HIST=true
if [ "$COMMIT_NOT_IN_HIST" != true ] ; then
    warn "repository is up to date!"
    exit 0
fi

echo "::endgroup::"

cmd_from_yml_file "prepull"

echo "::group::Pull template"

debug "create new branch from default branch with name ${NEW_BRANCH}"
git checkout -b "${NEW_BRANCH}"
debug "pull changes from template"

eval "git pull ${SOURCE_REPO} ${GIT_REMOTE_PULL_PARAMS}" || PULL_HAS_ISSUES=true

if [ "$PULL_HAS_ISSUES" == true ] ; then
    warn "There had been some git pull issues."
    warn "Maybe a merge issue."
    warn "We go on but it is likely that you need to fix merge issues within the created PR."
fi

echo "::endgroup::"

# Check if the Ignore File exists inside .github folder or if it doesn't exist at all
if [[ -f ".github/${TEMPLATE_SYNC_IGNORE_FILE_PATH}" || ! -f "${TEMPLATE_SYNC_IGNORE_FILE_PATH}" ]]; then
  debug "using ignore file as in .github folder"
  TEMPLATE_SYNC_IGNORE_FILE_PATH=".github/${TEMPLATE_SYNC_IGNORE_FILE_PATH}"
fi

if [ -s "${TEMPLATE_SYNC_IGNORE_FILE_PATH}" ]; then
  echo "::group::restore ignore file"
  info "restore the ignore file"
  git reset "${TEMPLATE_SYNC_IGNORE_FILE_PATH}"
  git checkout -- "${TEMPLATE_SYNC_IGNORE_FILE_PATH}" || warn "not able to checkout the former .templatesyncignore file. Most likely the file was not present"
  echo "::endgroup::"
fi

function force_delete_files() {
  echo "::group::force file deletion"
  warn "force file deletion is enabled. Deleting files which are deleted within the target repository"
  FILES_TO_DELETE=$(git log --diff-filter D --pretty="format:" --name-only "${LOCAL_CURRENT_GIT_HASH}"..HEAD | sed '/^$/d')
  warn "files to delete: ${FILES_TO_DELETE}"
  if [[ -n "${FILES_TO_DELETE}" ]]; then
    echo "${FILES_TO_DELETE}" | xargs rm
  fi

  echo "::endgroup::"
}

if [ "$IS_FORCE_DELETION" == "true" ]; then
  force_delete_files
fi

cmd_from_yml_file "precommit"

echo "::group::commit changes"

git add .

# we are checking the ignore file if it exists or is empty
# -s is true if the file contains whitespaces
if [ -s "${TEMPLATE_SYNC_IGNORE_FILE_PATH}" ]; then
  debug "unstage files from template sync ignore"
  git reset --pathspec-from-file="${TEMPLATE_SYNC_IGNORE_FILE_PATH}"

  debug "clean untracked files"
  git clean -df

  debug "discard all unstaged changes"
  git checkout -- .
fi

if git diff --quiet && git diff --staged --quiet; then
  info "nothing to commit"
  exit 0
fi

git commit --signoff -m "${PR_COMMIT_MSG}"

echo "::endgroup::"

function cleanup_older_prs () {
  older_prs=$(gh pr list \
  --base "${UPSTREAM_BRANCH}" \
  --state open \
  --label "${PR_LABELS}" \
  --json number \
  --template '{{range .}}{{printf "%v" .number}}{{"\n"}}{{end}}')

  for older_pr in $older_prs
  do
    gh pr close "$older_pr"
    debug "Closed PR #${older_pr}"
  done
}
echo "::group::cleanup older PRs"

if [ "$IS_DRY_RUN" != "true" ]; then
  if [ "$IS_PR_CLEANUP" != "false" ]; then
    if [[ -z "${PR_LABELS}" ]]; then
     warn "env var 'PR_LABELS' is empty. Skipping older prs cleanup"
    else
      cmd_from_yml_file "precleanup"
      cleanup_older_prs
    fi
  else
    warn "is_pr_cleanup option is set to off. Skipping older prs cleanup"
  fi
else
  warn "dry_run option is set to off. Skipping older prs cleanup"
fi

echo "::endgroup::"


function maybe_create_labels () {
  all_labels=${PR_LABELS//,/$'\n'}
  for label in $all_labels
  do
      search_result=$(gh label list \
      --search "${label}" \
      --limit 1 \
      --json name \
      --template '{{range .}}{{printf "%v" .name}}{{"\n"}}{{end}}')

      if [ "${search_result}" = "${label}" ]; then
        info "label '${label}' was found in the repository"
      else
        gh label create "${label}"
        info "label '${label}' was missing and has been created"
      fi
  done
}

echo "::group::check for missing labels"

if [[ -z "${PR_LABELS}" ]]; then
  info "env var 'PR_LABELS' is empty. Skipping labels check"
else
  if [ "$IS_DRY_RUN" != "true" ]; then
    maybe_create_labels
  else
    warn "dry_run option is set to off. Skipping labels check"
  fi
fi

echo "::endgroup::"

function push () {
  debug "push changes"
  git push --set-upstream origin "${NEW_BRANCH}"
}

function create_pr () {
  gh pr create \
        --title "${PR_TITLE}" \
        --body "Merge ${SOURCE_REPO_PATH} ${NEW_TEMPLATE_GIT_HASH}" \
        --base "${UPSTREAM_BRANCH}" \
        --label "${PR_LABELS}" \
        --reviewer "${PR_REVIEWERS}"
}

echo "::group::push changes and create PR"

if [ "$IS_DRY_RUN" != "true" ]; then
  cmd_from_yml_file "prepush"
  push
  cmd_from_yml_file "prepr"
  create_pr
else
    warn "dry_run option is set to off. Skipping push changes and skip create pr"
fi

echo "::endgroup::"
