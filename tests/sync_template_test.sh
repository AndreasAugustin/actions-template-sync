#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=tests/test_common.sh
source "${SCRIPT_DIR}/test_common.sh"

create_source_repository() {
  local temp_dir=$1
  local remote_dir="${temp_dir}/source.git"
  local work_dir="${temp_dir}/source-work"

  git init --bare --quiet "${remote_dir}"
  git init --quiet "${work_dir}"
  git -C "${work_dir}" config user.email test@example.com
  git -C "${work_dir}" config user.name test

  printf 'stable\n' > "${work_dir}/file"
  git -C "${work_dir}" add file
  git -C "${work_dir}" commit --quiet -m initial
  git -C "${work_dir}" tag v1.0.0
  git -C "${work_dir}" branch source-branch

  printf 'release\n' >> "${work_dir}/file"
  git -C "${work_dir}" add file
  git -C "${work_dir}" commit --quiet -m release
  git -C "${work_dir}" tag v2.0.0

  printf 'prerelease\n' >> "${work_dir}/file"
  git -C "${work_dir}" add file
  git -C "${work_dir}" commit --quiet -m prerelease
  git -C "${work_dir}" tag v9.0.0-rc1

  git -C "${work_dir}" push --quiet "${remote_dir}" HEAD --tags
  printf '%s\n' "${remote_dir}"
}

run_sync_to_latest_semver() {
  local temp_dir=$1
  local include_prerelease=$2
  local source_repository=$3
  local target_dir="${temp_dir}/target-${include_prerelease}"
  local output_file="${temp_dir}/output-${include_prerelease}"
  local github_output="${temp_dir}/github-output-${include_prerelease}"
  local fake_bin="${temp_dir}/bin"

  mkdir -p "${fake_bin}" "${target_dir}"
  printf '#!/usr/bin/env bash\nexit 0\n' > "${fake_bin}/gh"
  chmod +x "${fake_bin}/gh"

  git -C "${target_dir}" init --quiet
  git -C "${target_dir}" config user.email test@example.com
  git -C "${target_dir}" config user.name test
  git -C "${target_dir}" config pull.rebase false
  git -C "${target_dir}" commit --quiet --allow-empty -m target

  (
    cd "${target_dir}"
    PATH="${fake_bin}:${PATH}" \
      SOURCE_REPO="${source_repository}" \
      PR_COMMIT_MSG="sync" \
      GITHUB_SERVER_URL="https://github.com" \
      UPSTREAM_BRANCH="main" \
      TEMPLATE_SYNC_IGNORE_FILE_PATH=".templatesyncignore" \
      PR_BRANCH_NAME_PREFIX="chore/template_sync" \
      IS_FORCE_PUSH_PR=true \
      IS_DRY_RUN=true \
      IS_SYNC_TO_LATEST_SEMVER=true \
      IS_INCLUDE_PRERELEASE="${include_prerelease}" \
      STEPS="pull" \
      GITHUB_OUTPUT="${github_output}" \
      bash "${REPO_ROOT}/src/sync_template.sh"
  ) > "${output_file}"

  printf '%s\n' "${output_file}"
}

test_sync_uses_latest_stable_semver() {
  local temp_dir source_repository output_file output
  temp_dir=$(mktemp -d)
  source_repository=$(create_source_repository "${temp_dir}")
  output_file=$(run_sync_to_latest_semver "${temp_dir}" false "${source_repository}")
  output=$(<"${output_file}")

  assert_contains "::info::syncing to latest semantic version tag: v2.0.0" "${output}"
  [[ -f "${temp_dir}/target-false/file" ]]
  grep -q '^stable$' "${temp_dir}/target-false/file"
  grep -q '^release$' "${temp_dir}/target-false/file"
  if grep -q '^prerelease$' "${temp_dir}/target-false/file"; then
    return 1
  fi
  rm -rf "${temp_dir}"
}

test_sync_uses_latest_prerelease_when_enabled() {
  local temp_dir source_repository output_file output
  temp_dir=$(mktemp -d)
  source_repository=$(create_source_repository "${temp_dir}")
  output_file=$(run_sync_to_latest_semver "${temp_dir}" true "${source_repository}")
  output=$(<"${output_file}")

  assert_contains "::info::syncing to latest semantic version tag: v9.0.0-rc1" "${output}"
  [[ -f "${temp_dir}/target-true/file" ]]
  grep -q '^prerelease$' "${temp_dir}/target-true/file"
  rm -rf "${temp_dir}"
}

test_action_wires_semver_inputs() {
  local action
  action=$(<"${REPO_ROOT}/action.yml")
  assert_contains "is_sync_to_latest_semver:" "${action}"
  assert_contains "is_include_prerelease:" "${action}"
  assert_contains "IS_SYNC_TO_LATEST_SEMVER: \${{ inputs.is_sync_to_latest_semver }}" "${action}"
  assert_contains "IS_INCLUDE_PRERELEASE: \${{ inputs.is_include_prerelease }}" "${action}"
}

test_action_wires_source_branch_input() {
  local action
  action=$(<"${REPO_ROOT}/action.yml")
  assert_contains "source_branch:" "${action}"
  assert_contains "SOURCE_BRANCH: \${{ inputs.source_branch }}" "${action}"
}

it "syncs to the latest stable semantic version" test_sync_uses_latest_stable_semver
it "syncs to the latest prerelease when enabled" test_sync_uses_latest_prerelease_when_enabled
it "wires semantic-version inputs in action.yml" test_action_wires_semver_inputs
it "wires the source branch input in action.yml" test_action_wires_source_branch_input

finish_tests
