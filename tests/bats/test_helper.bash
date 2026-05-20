#!/usr/bin/env bash
# Shared test helper sourced by every .bats file via `load test_helper`.

# Make our vendored bats libraries (bats-support, bats-assert) discoverable by
# `bats_load_library` regardless of how bats is invoked (`make test`, direct
# `bats`, or CI's apt-installed bats). Derived from this file's own location
# via BASH_SOURCE so it works even when sourced from a deeper test directory.
_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BATS_LIB_PATH="${_HELPER_DIR}/lib${BATS_LIB_PATH:+:${BATS_LIB_PATH}}"

bats_load_library bats-support
bats_load_library bats-assert

# Path to the repo root, computed from this file's location.
REPO_ROOT="$(cd "${_HELPER_DIR}/../.." && pwd)"
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
