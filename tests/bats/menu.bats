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
