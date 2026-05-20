#!/usr/bin/env bats

load test_helper

setup() {
  load_lib state
  setup_tmp
  STATE_FILE="${TEST_TMP}/state.json"
  export STATE_FILE
}

@test "write_state: creates a JSON file with given fields + schema_version" {
  write_state "${STATE_FILE}" \
    assistant=open-webui \
    domain=chat.example.com \
    provider=anthropic
  assert [ -f "${STATE_FILE}" ]
  run jq -r '.schema_version' "${STATE_FILE}"
  assert_output "1"
  run jq -r '.assistant' "${STATE_FILE}"
  assert_output "open-webui"
  run jq -r '.domain' "${STATE_FILE}"
  assert_output "chat.example.com"
}

@test "write_state: preserves existing fields not in this call" {
  write_state "${STATE_FILE}" assistant=open-webui domain=chat.example.com
  write_state "${STATE_FILE}" provider=openai
  run jq -r '.assistant' "${STATE_FILE}"
  assert_output "open-webui"
  run jq -r '.provider' "${STATE_FILE}"
  assert_output "openai"
}

@test "read_state: returns value of an existing field" {
  write_state "${STATE_FILE}" assistant=open-webui
  run read_state "${STATE_FILE}" assistant
  assert_success
  assert_output "open-webui"
}

@test "read_state: returns empty + non-zero for a missing field" {
  write_state "${STATE_FILE}" assistant=open-webui
  run read_state "${STATE_FILE}" provider
  assert_failure
}

@test "add_extra: appends to .extras array, dedups, sorts" {
  write_state "${STATE_FILE}" assistant=open-webui
  add_extra "${STATE_FILE}" caddy
  add_extra "${STATE_FILE}" pwa
  add_extra "${STATE_FILE}" caddy
  run jq -c '.extras' "${STATE_FILE}"
  assert_output '["caddy","pwa"]'
}

@test "remove_extra: removes from .extras array" {
  write_state "${STATE_FILE}" assistant=open-webui
  add_extra "${STATE_FILE}" caddy
  add_extra "${STATE_FILE}" pwa
  remove_extra "${STATE_FILE}" caddy
  run jq -c '.extras' "${STATE_FILE}"
  assert_output '["pwa"]'
}
