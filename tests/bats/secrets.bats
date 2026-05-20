#!/usr/bin/env bats

load test_helper

setup() {
  load_lib secrets
  setup_tmp
  ENV_FILE="${TEST_TMP}/.env"
  export ENV_FILE
}

@test "write_env_var: creates file with mode 0600 and writes KEY=VALUE" {
  write_env_var "${ENV_FILE}" "OPENAI_API_KEY" "sk-test-123"
  assert [ -f "${ENV_FILE}" ]
  run bash -c "stat -c '%a' '${ENV_FILE}' 2>/dev/null || stat -f '%Lp' '${ENV_FILE}'"
  assert_output "600"
  run cat "${ENV_FILE}"
  assert_output --partial "OPENAI_API_KEY=sk-test-123"
}

@test "write_env_var: overwrites an existing key in-place" {
  printf 'OPENAI_API_KEY=old\nUNRELATED=keepme\n' > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  write_env_var "${ENV_FILE}" "OPENAI_API_KEY" "sk-new"
  run cat "${ENV_FILE}"
  assert_output --partial "OPENAI_API_KEY=sk-new"
  assert_output --partial "UNRELATED=keepme"
  refute_output --partial "OPENAI_API_KEY=old"
}

@test "read_env_var: returns value of existing key" {
  printf 'OPENAI_API_KEY=sk-test-123\n' > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  run read_env_var "${ENV_FILE}" "OPENAI_API_KEY"
  assert_success
  assert_output "sk-test-123"
}

@test "read_env_var: empty output and non-zero exit when missing" {
  echo "" > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  run read_env_var "${ENV_FILE}" "MISSING_KEY"
  assert_failure
  assert_output ""
}

@test "shred_env: removes the env file" {
  printf 'X=1\n' > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  shred_env "${ENV_FILE}"
  assert [ ! -f "${ENV_FILE}" ]
}

@test "shred_env: no-op when file is absent" {
  run shred_env "${TEST_TMP}/does-not-exist"
  assert_success
}
