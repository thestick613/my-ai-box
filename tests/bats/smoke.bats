#!/usr/bin/env bats

load test_helper

@test "bats harness is wired up correctly" {
  run echo "hello"
  assert_success
  assert_output "hello"
}

@test "REPO_ROOT points at a directory with LICENSE" {
  assert [ -f "${REPO_ROOT}/LICENSE" ]
}
