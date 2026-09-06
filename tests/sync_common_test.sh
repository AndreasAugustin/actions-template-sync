#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=src/sync_common.sh
source "${REPO_ROOT}/src/sync_common.sh"

PASS_COUNT=0
FAIL_COUNT=0

describe() {
  printf '\n%s\n' "$1"
}

it() {
  local description=$1
  shift

  if "$@"; then
    printf '  \033[32m✓\033[0m %s\n' "${description}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf '  \033[31m✗\033[0m %s\n' "${description}" >&2
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_contains() {
  local expected=$1
  local actual=$2
  [[ "${actual}" == *"${expected}"* ]]
}

assert_equal() {
  [[ "$1" == "$2" ]]
}

test_info_logs_an_info_message() {
  local output
  output=$(info "hello")
  assert_equal "::info::hello" "${output}"
}

test_warn_logs_a_warning_message() {
  local output
  output=$(warn "be careful")
  assert_equal "::warn::be careful" "${output}"
}

test_debug_logs_a_debug_message() {
  local output
  output=$(debug "details")
  assert_equal "::debug::details" "${output}"
}

test_starts_and_ends_log_groups() {
  local output
  output=$(start_group "setup")
  assert_equal "::group::setup" "${output}"
  output=$(end_group)
  assert_equal "::endgroup::" "${output}"
}

test_latest_semantic_version_tag_from_remote() {
  local temp_dir remote_dir output
  temp_dir=$(mktemp -d)
  remote_dir="${temp_dir}/remote.git"

  (
    cd "${temp_dir}"
    git init --quiet
    git config user.email test@example.com
    git config user.name test
    touch file
    git add file
    git commit --quiet -m initial
    git tag v1.0.0
    git tag v2.0.0
    git tag not-a-version
    git init --bare --quiet "${remote_dir}"
    git push --quiet "${remote_dir}" HEAD --tags
    output=$(get_latest_semantic_version_tag "${remote_dir}")
    assert_equal "::info::v2.0.0" "${output}"
  )
  rm -rf "${temp_dir}"
}

test_latest_semantic_version_tag_excludes_prereleases_by_default() {
  local temp_dir remote_dir output
  temp_dir=$(mktemp -d)
  remote_dir="${temp_dir}/remote.git"

  (
    cd "${temp_dir}"
    git init --quiet
    git config user.email test@example.com
    git config user.name test
    touch file
    git add file
    git commit --quiet -m initial
    git tag v1.0.0
    git tag v9.0.0-rc1
    git tag not-a-version
    git init --bare --quiet "${remote_dir}"
    git push --quiet "${remote_dir}" HEAD --tags
    output=$(get_latest_semantic_version_tag "${remote_dir}")
    assert_equal "::info::v1.0.0" "${output}"
  )
  rm -rf "${temp_dir}"
}

test_latest_semantic_version_tag_includes_prereleases_when_requested() {
  local temp_dir remote_dir output
  temp_dir=$(mktemp -d)
  remote_dir="${temp_dir}/remote.git"

  (
    cd "${temp_dir}"
    git init --quiet
    git config user.email test@example.com
    git config user.name test
    touch file
    git add file
    git commit --quiet -m initial
    git tag v1.0.0
    git tag v9.0.0-rc1
    git tag not-a-version
    git init --bare --quiet "${remote_dir}"
    git push --quiet "${remote_dir}" HEAD --tags
    output=$(get_latest_semantic_version_tag "${remote_dir}" true)
    assert_equal "::info::v9.0.0-rc1" "${output}"
  )
  rm -rf "${temp_dir}"
}

test_latest_semantic_version_tag_requires_remote() {
  local output
  if output=$(get_latest_semantic_version_tag "" 2>&1); then
    return 1
  fi
  assert_contains "Missing variable 'remote_repository'." "${output}"
}

test_latest_semantic_version_tag_rejects_invalid_prerelease_option() {
  local output
  if output=$(get_latest_semantic_version_tag remote invalid 2>&1); then
    return 1
  fi
  assert_contains "Invalid value for 'include_prerelease'" "${output}"
}

test_latest_semantic_version_tag_reports_missing_tags() {
  local temp_dir remote_dir output
  temp_dir=$(mktemp -d)
  remote_dir="${temp_dir}/remote.git"

  (
    git init --bare --quiet "${remote_dir}"
    if output=$(get_latest_semantic_version_tag "${remote_dir}" 2>&1); then
      return 1
    fi
    assert_contains "No semantic version tag found" "${output}"
  )
  rm -rf "${temp_dir}"
}

test_latest_semantic_version_tag_does_not_use_local_tags() {
  local temp_dir remote_dir output
  temp_dir=$(mktemp -d)
  remote_dir="${temp_dir}/remote.git"

  (
    cd "${temp_dir}"
    git init --quiet
    git config user.email test@example.com
    git config user.name test
    touch file
    git add file
    git commit --quiet -m initial
    git tag v1.0.0
    git init --bare --quiet "${remote_dir}"
    git push --quiet "${remote_dir}" HEAD --tags
    git tag v9.0.0
    output=$(get_latest_semantic_version_tag "${remote_dir}")
    assert_equal "::info::v1.0.0" "${output}"
  )
  rm -rf "${temp_dir}"
}

test_err_logs_an_error_message() {
  local output
  output=$(err "failed" 2>&1)
  assert_contains "::error::" "${output}"
  assert_contains "failed" "${output}"
}

test_hooks_are_skipped_when_disabled() {
  local temp_dir output
  temp_dir=$(mktemp -d)

  (
    cd "${temp_dir}"
    IS_ALLOW_HOOKS=false
    output=$(cmd_from_yml "precommit")
    assert_equal "::debug::execute cmd hooks not enabled" "${output}"
  )
  rm -rf "${temp_dir}"
}

test_hooks_execute_commands_from_input() {
  local temp_dir output
  temp_dir=$(mktemp -d)

  mkdir -p "${temp_dir}/bin"
  printf '#!/usr/bin/env bash\nprintf "printf hooked-command\\n"\n' \
    > "${temp_dir}/bin/yq"
  chmod +x "${temp_dir}/bin/yq"

  (
    cd "${temp_dir}"
    PATH="${temp_dir}/bin:${PATH}"
    IS_ALLOW_HOOKS=true
    HOOKS='hooks: []'
    output=$(cmd_from_yml "precommit")
    assert_contains "::info::execute cmd hooks enabled" "${output}"
    assert_contains "hooked-command" "${output}"
    [[ ! -e tmp.templatesync.yml ]]
  )
  rm -rf "${temp_dir}"
}

describe "sync_common logging"
it "logs info messages" test_info_logs_an_info_message
it "logs warning messages" test_warn_logs_a_warning_message
it "logs debug messages" test_debug_logs_a_debug_message
it "starts and ends log groups" test_starts_and_ends_log_groups
it "gets the latest semantic version tag from a remote" test_latest_semantic_version_tag_from_remote
it "excludes prereleases by default" test_latest_semantic_version_tag_excludes_prereleases_by_default
it "includes prereleases when requested" test_latest_semantic_version_tag_includes_prereleases_when_requested
it "requires a remote repository" test_latest_semantic_version_tag_requires_remote
it "rejects an invalid prerelease option" test_latest_semantic_version_tag_rejects_invalid_prerelease_option
it "reports missing semantic version tags" test_latest_semantic_version_tag_reports_missing_tags
it "does not use local tags" test_latest_semantic_version_tag_does_not_use_local_tags
it "logs error messages" test_err_logs_an_error_message

describe "sync_common hooks"
it "skips hooks when disabled" test_hooks_are_skipped_when_disabled
it "executes commands from hook input" test_hooks_execute_commands_from_input

printf '\n%d passed, %d failed\n' "${PASS_COUNT}" "${FAIL_COUNT}"
[[ "${FAIL_COUNT}" -eq 0 ]]
