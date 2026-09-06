#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=src/sync_common.sh
source "${REPO_ROOT}/src/sync_common.sh"

PASS_COUNT=0
FAIL_COUNT=0

describe() {
  info "TEST SUITE: $1"
}

it() {
  local description=$1
  shift

  if "$@"; then
    info "PASS: ${description}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    warn "FAIL: ${description}"
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

finish_tests() {
  info "TEST RESULTS: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
  [[ "${FAIL_COUNT}" -eq 0 ]]
}
