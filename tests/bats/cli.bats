#!/usr/bin/env bats

load test_helper

@test "my-ai-box: prints help on --help" {
  run "${REPO_ROOT}/bin/my-ai-box" --help
  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "install"
  assert_output --partial "menu"
}

@test "my-ai-box: prints version on --version" {
  run "${REPO_ROOT}/bin/my-ai-box" --version
  assert_success
  assert_output --partial "my-ai-box"
}

@test "my-ai-box: unknown command exits non-zero with help pointer" {
  run "${REPO_ROOT}/bin/my-ai-box" not-a-real-command
  assert_failure
  assert_output --partial "unknown command"
}
