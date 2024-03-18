#!/usr/bin/env bash

set -e
# set -u
# set -x

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# shellcheck source=src/sync_template.sh
source "${SCRIPT_DIR}/sync_common.sh"

############################################
# Prechecks
############################################

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

########################################################
# Variables
########################################################

if [[ -z "${UPSTREAM_BRANCH}" ]]; then
  UPSTREAM_BRANCH="$(git remote show origin | awk '/HEAD branch/ {print $NF}')"
  info "Missing env variable 'UPSTREAM_BRANCH' setting to remote default ${UPSTREAM_BRANCH}";
fi

if [[ -n "${SRC_SSH_PRIVATEKEY_ABS_PATH}" ]]; then
  debug "using ssh private key for private source repository"
  export GIT_SSH_COMMAND="ssh -i ${SRC_SSH_PRIVATEKEY_ABS_PATH}"
fi

IS_FORCE_PUSH_PR="${IS_FORCE_PUSH_PR:-"false"}"
GIT_REMOTE_PULL_PARAMS="${GIT_REMOTE_PULL_PARAMS:---allow-unrelated-histories --squash --strategy=recursive -X theirs}"

TEMPLATE_SYNC_IGNORE_FILE_PATH=".templatesyncignore"
TEMPLATE_REMOTE_GIT_HASH=$(git ls-remote "${SOURCE_REPO}" HEAD | awk '{print $1}')
SHORT_TEMPLATE_GIT_HASH=$(git rev-parse --short "${TEMPLATE_REMOTE_GIT_HASH}")

export TEMPLATE_GIT_HASH=${SHORT_TEMPLATE_GIT_HASH}
export NEW_BRANCH="${PR_BRANCH_NAME_PREFIX}_${TEMPLATE_GIT_HASH}"
: "${PR_BODY:="Merge ${SOURCE_REPO_PATH} ${TEMPLATE_GIT_HASH}"}"
PR_TITLE_TMP="${PR_TITLE:-"upstream merge template repository"}"

debug "TEMPLATE_GIT_HASH ${TEMPLATE_GIT_HASH}"
debug "NEW_BRANCH ${NEW_BRANCH}"
info "PR_BODY ${PR_BODY}"
info "PR_BODY_TMP ${PR_BODY_TMP}"

# shellcheck disable=SC2016
PR_BODY=${PR_BODY//'${TEMPLATE_GIT_HASH}'/"${TEMPLATE_GIT_HASH}"}
PR_BODY=${PR_BODY//'${SOURCE_REPO}'/"${SOURCE_REPO}"}
info "SOURCE_REPO ${SOURCE_REPO}"
export TMP="${PR_BODY}"
info "TMP ${TMP}"

# Check if the Ignore File exists inside .github folder or if it doesn't exist at all
if [[ -f ".github/${TEMPLATE_SYNC_IGNORE_FILE_PATH}" || ! -f "${TEMPLATE_SYNC_IGNORE_FILE_PATH}" ]]; then
  debug "using ignore file as in .github folder"
  TEMPLATE_SYNC_IGNORE_FILE_PATH=".github/${TEMPLATE_SYNC_IGNORE_FILE_PATH}"
fi

#####################################################
# Functions
#####################################################

#######################################
# set the gh action outputs if run with github action.
# Arguments:
#   pr_branch
#######################################
function set_github_action_outputs() {
  echo "::group::set gh action outputs"

  local pr_branch=$1
  info "set github action outputs"

  if [[ -z "${GITHUB_RUN_ID}" ]]; then
    info "env var 'GITHUB_RUN_ID' is empty -> no github action workflow"
  else
    # https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-output-parameter
    echo "pr_branch=${pr_branch}" >> "$GITHUB_OUTPUT"
  fi
  echo "::endgroup::"
}

#######################################
# Check if the branch exists remote.
# Arguments:
#   pr_branch
#######################################
function check_branch_remote_existing() {

  local branch_to_check=$1

  info "check if the remote branch ${branch_to_check} exists. Exit if so"

  git ls-remote --exit-code --heads origin "${branch_to_check}" || branch_does_not_exist=true

  if [[ "${branch_does_not_exist}" != true ]]; then
    warn "Git branch '${branch_to_check}' exists in the remote repository"
    set_github_action_outputs "${branch_to_check}"
    exit 0
  fi
}

#######################################
# Check if the commit is already in history.
# exit 0 if so
# Arguments:
#   template_remote_git_hash
#######################################
function check_if_commit_already_in_hist_graceful_exit() {
  info "check if commit already in history"

  local template_remote_git_hash=$1

  git cat-file -e "${template_remote_git_hash}" || commit_not_in_hist=true
  if [ "${commit_not_in_hist}" != true ] ; then
      warn "repository is up to date!"
      exit 0
  fi

}

##########################################
# check if there are staged files.
# exit if not
##########################################
function check_staged_files_available_graceful_exit() {
  if git diff --quiet && git diff --staged --quiet; then
    info "nothing to commit"
    exit 0
  fi
}

#######################################
# force source file deletion if they had been deleted
#######################################
function force_delete_files() {
  info "force delete files"
  warn "force file deletion is enabled. Deleting files which are deleted within the target repository"
  local_current_git_hash=$(git rev-parse HEAD)

  info "current git hash: ${local_current_git_hash}"

  files_to_delete=$(git log --diff-filter D --pretty="format:" --name-only "${local_current_git_hash}"..HEAD | sed '/^$/d')
  warn "files to delete: ${files_to_delete}"
  if [[ -n "${files_to_delete}" ]]; then
    echo "${files_to_delete}" | xargs rm
  fi
}

#######################################
# cleanup older prs based on labels.
# Arguments:
#   upstream_branch
#   pr_labels
#######################################
function cleanup_older_prs () {
  info "cleanup older prs"

  local upstream_branch=$1
  local pr_labels=$2

  if [[ -z "${pr_labels}" ]]; then
     warn "env var 'PR_LABELS' is empty. Skipping older prs cleanup"
     return 0
  fi

  older_prs=$(gh pr list \
  --base "${upstream_branch}" \
  --state open \
  --label "${pr_labels}" \
  --json number \
  --template '{{range .}}{{printf "%v" .number}}{{"\n"}}{{end}}')

  for older_pr in $older_prs
  do
    gh pr close "$older_pr"
    debug "Closed PR #${older_pr}"
  done
}

##################################
# pull source changes
# Arguments:
#   source_repo
#   git_remote_pull_params
##################################
function pull_source_changes() {
  info "pull changes from source repository"
  local source_repo=$1
  local git_remote_pull_params=$2

  eval "git pull ${source_repo} ${git_remote_pull_params}" || pull_has_issues=true

  if [ "$pull_has_issues" == true ] ; then
      warn "There had been some git pull issues."
      warn "Maybe a merge issue."
      warn "We go on but it is likely that you need to fix merge issues within the created PR."
  fi
}

#######################################
# eventual create labels (if they are not existent).
# Arguments:
#   pr_labels
#######################################
function eventual_create_labels () {
  local pr_labels=$1
  info "eventual create labels ${pr_labels}"

  if [[ -z "${pr_labels}" ]]; then
    info "'pr_labels' is empty. Skipping labels check"
    retun 0
  fi

  readarray -t labels_array < <(awk -F',' '{ for( i=1; i<=NF; i++ ) print $i }' <<<"${pr_labels}")
  for label in "${labels_array[@]}"
  do
      search_result=$(gh label list \
      --search "${label}" \
      --limit 1 \
      --json name \
      --template '{{range .}}{{printf "%v" .name}}{{"\n"}}{{end}}')

      if [ "${search_result}" = "${label##[[:space:]]}" ]; then
        info "label '${label##[[:space:]]}' was found in the repository"
      else
        if gh label create "${label}"; then
          info "label '${label}' was missing and has been created"
        else
          warn "label creation did not work. For any reason the former check sometimes is failing"
        fi
      fi
  done
}

##############################
# push the changes
# Arguments:
#   branch
#   is_force
##############################
function push () {
  info "push changes"
  local branch=$1
  local is_force=$2

  if [ "$is_force" == true ] ; then
      warn "forcing the push."
      git push --force --set-upstream origin "${branch}"
  else
    git push --set-upstream origin "${branch}"
  fi
}

####################################
# creates a pr
# Arguments:
#   title
#   body
#   branch
#   labels
#   reviewers
###################################
function create_pr() {
  info "create pr"
  local title=$1
  local body=$2
  local branch=$3
  local labels=$4
  local reviewers=$5

  gh pr create \
        --title "${title}" \
        --body "${body}" \
        --base "${branch}" \
        --label "${labels}" \
        --reviewer "${reviewers}" || create_pr_has_issues=true

  if [ "$create_pr_has_issues" == true ] ; then
      warn "Creating the PR failed."
      warn "Eventually it is already existent."
      return 1
  fi
  return 0
}

####################################
# creates or edits a pr if already existent
# Arguments:
#   title
#   body
#   branch
#   labels
#   reviewers
###################################
function create_or_edit_pr() {
  info "create pr or edit the pr"
  local title=$1
  local body=$2
  local branch=$3
  local labels=$4
  local reviewers=$5

  create_pr "${title}" "${body}" "${branch}" "${labels}" "${reviewers}" || gh pr edit \
    --title "${title}" \
    --body "${body}" \
    --add-label "${labels}" \
    --add-reviewer "${reviewers}"
}

#########################################
# restore the .templatesyncignore file
# Arguments:
#   template_sync_ignore_file_path
###########################################
function restore_templatesyncignore_file() {
  info "restore the ignore file"
  local template_sync_ignore_file_path=$1
  if [ -s "${template_sync_ignore_file_path}" ]; then
    git reset "${template_sync_ignore_file_path}"
    git checkout -- "${template_sync_ignore_file_path}" || warn "not able to checkout the former .templatesyncignore file. Most likely the file was not present"
  fi
}

#########################################
# reset all files within the .templatesyncignore file
# Arguments:
#   template_sync_ignore_file_path
###########################################
function handle_templatesyncignore() {
  info "handle .templatesyncignore"
  local template_sync_ignore_file_path=$1
  # we are checking the ignore file if it exists or is empty
  # -s is true if the file contains whitespaces
  if [ -s "${template_sync_ignore_file_path}" ]; then
    debug "unstage files from template sync ignore"
    git reset --pathspec-from-file="${template_sync_ignore_file_path}"

    debug "clean untracked files"
    git clean -df

    debug "discard all unstaged changes"
    git checkout -- .
  fi
}

########################################################
# Logic
#######################################################

function prechecks() {
  info "prechecks"
  echo "::group::prechecks"
  if [ "${IS_FORCE_PUSH_PR}" == "true" ]; then
    warn "skipping prechecks because we force push and pr"
    return 0
  fi
  check_branch_remote_existing "${NEW_BRANCH}"

  check_if_commit_already_in_hist_graceful_exit "${TEMPLATE_REMOTE_GIT_HASH}"

  echo "::endgroup::"
}


function checkout_branch_and_pull() {
  info "checkout branch and pull"
  cmd_from_yml "prepull"

  echo "::group::checkout branch and pull"

  debug "create new branch from default branch with name ${NEW_BRANCH}"
  git checkout -b "${NEW_BRANCH}"
  debug "pull changes from template"

  pull_source_changes "${SOURCE_REPO}" "${GIT_REMOTE_PULL_PARAMS}"

  restore_templatesyncignore_file "${TEMPLATE_SYNC_IGNORE_FILE_PATH}"

  if [ "$IS_FORCE_DELETION" == "true" ]; then
    force_delete_files
  fi

  echo "::endgroup::"
}


function commit() {
  info "commit"

  cmd_from_yml "precommit"

  echo "::group::commit changes"

  git add .

  handle_templatesyncignore "${TEMPLATE_SYNC_IGNORE_FILE_PATH}"

  check_staged_files_available_graceful_exit

  git commit --signoff -m "${PR_COMMIT_MSG}"

  echo "::endgroup::"
}


function push_prepare_pr_create_pr() {
  info "push_prepare_pr_create_pr"
  if [ "$IS_DRY_RUN" == "true" ]; then
    warn "dry_run option is set to on. skipping labels check, cleanup older PRs, push and create pr"
    return 0
  fi
  echo "::group::check for missing labels"

  eventual_create_labels "${PR_LABELS}"

  echo "::endgroup::"

  echo "::group::cleanup older PRs"
  if [ "$IS_PR_CLEANUP" != "false" ]; then
    if [[ -z "${PR_LABELS}" ]]; then
    warn "env var 'PR_LABELS' is empty. Skipping older prs cleanup"
    else
      cmd_from_yml "precleanup"
      cleanup_older_prs "${UPSTREAM_BRANCH}" "${PR_LABELS}"
    fi
  else
    warn "is_pr_cleanup option is set to off. Skipping older prs cleanup"
  fi

  echo "::endgroup::"

  echo "::group::push changes and create PR"

  cmd_from_yml "prepush"
  push "${NEW_BRANCH}" "${IS_FORCE_PUSH_PR}"
  cmd_from_yml "prepr"
  if [ "$IS_FORCE_PUSH_PR" == true ] ; then
    create_or_edit_pr "${PR_TITLE}" "${PR_BODY}" "${UPSTREAM_BRANCH}" "${PR_LABELS}" "${PR_REVIEWERS}"
  else
    create_pr "${PR_TITLE}" "${PR_BODY}" "${UPSTREAM_BRANCH}" "${PR_LABELS}" "${PR_REVIEWERS}"
  fi


  echo "::endgroup::"
}


prechecks

checkout_branch_and_pull

commit

push_prepare_pr_create_pr

set_github_action_outputs "${NEW_BRANCH}"
