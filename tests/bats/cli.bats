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

@test "my-ai-box install: NONINTERACTIVE mode fails with a clear list of missing vars" {
  MY_AI_BOX_NONINTERACTIVE=1 run "${REPO_ROOT}/bin/my-ai-box" install
  assert_failure
  assert_output --partial "missing required env vars"
  assert_output --partial "MY_AI_BOX_ASSISTANT"
}

@test "my-ai-box install: --dry-run + env vars writes state and renders compose without docker" {
  setup_tmp
  local fake_root="${TEST_TMP}/opt/my-ai-box"
  mkdir -p "${fake_root}/data"

  # Set up a fake repo structure with assistants/open-webui/ since the wizard
  # reads from REPO_ROOT for compose templates.
  mkdir -p "${fake_root}/assistants/open-webui"
  cat > "${fake_root}/assistants/open-webui/compose.yml" <<EOF
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:0.6.32
EOF

  MY_AI_BOX_DRY_RUN=1 \
  MY_AI_BOX_RUNTIME_DIR="${fake_root}" \
  MY_AI_BOX_REPO_ROOT="${fake_root}" \
  MY_AI_BOX_ASSISTANT=open-webui \
  MY_AI_BOX_DOMAIN=chat.example.com \
  MY_AI_BOX_EMAIL=you@example.com \
  MY_AI_BOX_PROVIDER=anthropic \
  MY_AI_BOX_API_KEY=sk-test-123 \
  MY_AI_BOX_EXTRAS= \
  MY_AI_BOX_NONINTERACTIVE=1 \
    run "${REPO_ROOT}/bin/my-ai-box" install
  assert_success
  assert [ -f "${fake_root}/state.json" ]
  assert [ -f "${fake_root}/.env" ]
  assert [ -f "${fake_root}/compose.yml" ]
}
