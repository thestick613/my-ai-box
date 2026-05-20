#!/usr/bin/env bash
# Shared test helper sourced by every .bats file via `load test_helper`.

bats_load_library bats-support
bats_load_library bats-assert

# Path to the repo root, computed from this file's location.
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
export REPO_ROOT

# Convenience: source a library file under lib/ for tests.
load_lib() {
  local name="$1"
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/lib/${name}.sh"
}

# Create a per-test temp dir under BATS_TEST_TMPDIR.
setup_tmp() {
  TEST_TMP="${BATS_TEST_TMPDIR}/work"
  mkdir -p "${TEST_TMP}"
  export TEST_TMP
}
