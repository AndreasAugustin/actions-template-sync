#!/usr/bin/env bash

set -e
# set -u
# set -x

#######################################
# write a message to STDERR.
# Arguments:
#   message to print.
#######################################
function err() {
  echo "::error::[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2;
}

#######################################
# write a debug message.
# Arguments:
#   message to print.
#######################################
function debug() {
  echo "::debug::$*";
}

#######################################
# write a warn message.
# Arguments:
#   message to print.
#######################################
function warn() {
  echo "::warn::$*";
}

#######################################
# write a info message.
# Arguments:
#   message to print.
#######################################
function info() {
  echo "::info::$*";
}

#######################################
# Start a GitHub Actions log group.
# Arguments:
#   group name
#######################################
function start_group() {
  echo "::group::$*";
}

#######################################
# End a GitHub Actions log group.
#######################################
function end_group() {
  echo "::endgroup::";
}

#######################################
# Get the latest semantic version tag from a remote repository.
# Arguments:
#   remote_repository
#   include_prerelease (optional, defaults to false)
# Outputs:
#   the latest semantic version tag
#######################################
function get_latest_semantic_version_tag() {
  local remote_repository=$1
  local include_prerelease=${2:-false}
  local remote_tags
  local tag

  if [[ -z "${remote_repository}" ]]; then
    err "Missing variable 'remote_repository'."
    return 1
  fi

  if [[ "${include_prerelease}" != true && "${include_prerelease}" != false ]]; then
    err "Invalid value for 'include_prerelease': '${include_prerelease}'. Expected true or false."
    return 1
  fi

  if ! remote_tags=$(git ls-remote --tags --refs "${remote_repository}"); then
    err "Unable to list tags from remote repository '${remote_repository}'."
    return 1
  fi

  while IFS= read -r tag; do
    if [[ "${tag}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ||
      ( "${include_prerelease}" == true &&
        "${tag}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+-[0-9A-Za-z.-]+$ ) ]]; then
      info "${tag}"
      return 0
    fi
  done < <(
    awk '{sub("refs/tags/", "", $2); print $2}' <<< "${remote_tags}" |
      sort -Vr
  )

  err "No semantic version tag found in remote repository '${remote_repository}'."
  return 1
}

#######################################
# Executes commands defined within yml file or env variable
# Arguments:
#   hook -> the hook to use
#
####################################3#
function cmd_from_yml() {
  local FILE_NAME="templatesync.yml"
  local HOOK=$1
  local YML_PATH_SUFF=".${HOOK}.commands"

  if [ "$IS_ALLOW_HOOKS" != "true" ]; then
    debug "execute cmd hooks not enabled"
  else
    info "execute cmd hooks enabled"

    if ! [ -x "$(command -v yq)" ]; then
      err "yaml query yq is not installed. 'https://mikefarah.gitbook.io/yq/'";
      exit 1;
    fi

    if [[ -n "${HOOKS}" ]]; then
      debug "hooks input variable is set. Using the variable"
      echo "${HOOKS}" > "tmp.${FILE_NAME}"
      YML_PATH="${YML_PATH_SUFF}"
    else
      cp ${FILE_NAME} "tmp.${FILE_NAME}"
      YML_PATH=".hooks${YML_PATH_SUFF}"
    fi

    readarray cmd_Arr < <(yq "${YML_PATH} | .[]"  "tmp.${FILE_NAME}")

    rm "tmp.${FILE_NAME}"

    for key in "${cmd_Arr[@]}"; do echo "${key}" | bash; done
  fi
}
