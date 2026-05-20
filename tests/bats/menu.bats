#!/usr/bin/env bats

load test_helper

setup() {
  load_lib menu
  setup_tmp
}

@test "prompt_choice: returns selected index for valid numeric input" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "2" | prompt_choice "Pick" "Apple" "Banana" "Cherry"'
  assert_success
  assert_output --partial "Banana"
}

@test "prompt_choice: defaults to choice 1 when input is empty" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "" | prompt_choice "Pick" "Apple" "Banana"'
  assert_success
  assert_output --partial "Apple"
}

@test "prompt_choice: re-prompts on invalid input then accepts a valid one" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; printf "99\n2\n" | prompt_choice "Pick" "Apple" "Banana"'
  assert_success
  assert_output --partial "Banana"
  assert_output --partial "invalid"
}

@test "prompt_yesno: Y default + empty input -> yes" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "" | prompt_yesno "Continue?" "Y" && echo "YES" || echo "NO"'
  assert_success
  assert_output --partial "YES"
}

@test "prompt_yesno: N default + empty input -> no" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "" | prompt_yesno "Continue?" "N" && echo "YES" || echo "NO"'
  assert_output --partial "NO"
}

@test "prompt_yesno: 'y' input -> yes regardless of default" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "y" | prompt_yesno "Continue?" "N" && echo "YES" || echo "NO"'
  assert_output --partial "YES"
}

@test "prompt_string: returns the typed value" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "chat.example.com" | prompt_string "Domain" ""'
  assert_success
  assert_output --partial "chat.example.com"
}

@test "prompt_string: returns the default when input is empty" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "" | prompt_string "Domain" "default.example"'
  assert_success
  assert_output --partial "default.example"
}
