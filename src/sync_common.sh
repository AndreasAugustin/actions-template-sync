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
  return $?
}

#######################################
# write a debug message.
# Arguments:
#   message to print.
#######################################
function debug() {
  echo "::debug::$*";
  return $?
}

#######################################
# write a warn message.
# Arguments:
#   message to print.
#######################################
function warn() {
  echo "::warn::$*";
  return $?
}

#######################################
# write a info message.
# Arguments:
#   message to print.
#######################################
function info() {
  echo "::info::$*";
  return $?
}

#######################################
# Start a GitHub Actions log group.
# Arguments:
#   group name
#######################################
function start_group() {
  echo "::group::$*";
  return $?
}

#######################################
# End a GitHub Actions log group.
#######################################
function end_group() {
  echo "::endgroup::";
  return $?
}

#######################################
# Check whether a string is a semantic version.
# Arguments:
#   version
# Returns:
#   0 if the string is a semantic version, otherwise 1
#######################################
function is_semver() {
  local version=${1:-}

  [[ "${version}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([\-][0-9A-Za-z.-]+)?$ ]]
  return $?
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
    if is_semver "${tag}" &&
      [[ "${include_prerelease}" == true || "${tag}" != *-* ]]; then
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
# Get the commit hash referenced by a remote tag.
# Arguments:
#   remote_repository
#   tag_reference
# Outputs:
#   the tag commit hash
#######################################
function get_remote_tag_commit() {
  local remote_repository=$1
  local tag_reference=$2
  local remote_refs
  local commit

  if [[ -z "${remote_repository}" ]]; then
    err "Missing variable 'remote_repository'."
    return 1
  fi

  if [[ -z "${tag_reference}" ]]; then
    err "Missing variable 'tag_reference'."
    return 1
  fi

  if ! remote_refs=$(git ls-remote "${remote_repository}" "${tag_reference}" "${tag_reference}^{}"); then
    err "Unable to resolve tag '${tag_reference}' from remote repository '${remote_repository}'."
    return 1
  fi

  commit=$(
    awk -v tag_reference="${tag_reference}" '
      $2 == tag_reference "^{}" { print $1; found = 1; exit }
      $2 == tag_reference { fallback = $1 }
      END {
        if (!found && fallback != "") {
          print fallback
        }
      }' <<< "${remote_refs}"
  )

  if [[ -z "${commit}" ]]; then
    err "Tag '${tag_reference}' was not found in remote repository '${remote_repository}'."
    return 1
  fi

  printf '%s\n' "${commit}"
  return $?
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

  return $?
}
