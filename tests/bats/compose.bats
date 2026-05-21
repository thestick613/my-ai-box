#!/usr/bin/env bats

load test_helper

setup() {
  load_lib compose
  setup_tmp
  REPO="${TEST_TMP}/repo"
  RUNTIME="${TEST_TMP}/runtime"
  mkdir -p "${REPO}/assistants/open-webui" "${REPO}/extras/caddy" "${RUNTIME}"

  cat > "${REPO}/assistants/open-webui/compose.yml" <<EOF
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:0.6.32
EOF
  cat > "${REPO}/extras/caddy/compose-overlay.yml" <<EOF
services:
  caddy:
    image: caddy:2.10
EOF
}

@test "compose_render: copies assistant compose to runtime/compose.yml" {
  compose_render "${REPO}" "${RUNTIME}" "open-webui" ""
  assert [ -f "${RUNTIME}/compose.yml" ]
  run grep "open-webui" "${RUNTIME}/compose.yml"
  assert_success
}

@test "compose_render: writes compose.override.yml when extras are present" {
  compose_render "${REPO}" "${RUNTIME}" "open-webui" "caddy"
  assert [ -f "${RUNTIME}/compose.override.yml" ]
  run grep "caddy" "${RUNTIME}/compose.override.yml"
  assert_success
}

@test "compose_render: removes compose.override.yml when no extras are present" {
  : > "${RUNTIME}/compose.override.yml"
  compose_render "${REPO}" "${RUNTIME}" "open-webui" ""
  assert [ ! -f "${RUNTIME}/compose.override.yml" ]
}
