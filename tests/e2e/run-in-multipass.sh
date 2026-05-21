#!/usr/bin/env bash
# tests/e2e/run-in-multipass.sh
# Runs the dry-run install inside a fresh Multipass VM and asserts artifacts.
set -euo pipefail

VM_NAME="my-ai-box-e2e-$RANDOM"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cleanup() {
  multipass delete "${VM_NAME}" 2>/dev/null || true
  multipass purge 2>/dev/null || true
}
trap cleanup EXIT

echo "[e2e] launching VM ${VM_NAME}…"
multipass launch 24.04 --name "${VM_NAME}" --cpus 2 --memory 2G --disk 10G

echo "[e2e] mounting repo into VM…"
multipass mount "${REPO_ROOT}" "${VM_NAME}:/repo"

echo "[e2e] running dry-run install…"
multipass exec "${VM_NAME}" -- sudo bash -c '
  set -euo pipefail
  MY_AI_BOX_DRY_RUN=1 \
  MY_AI_BOX_RUNTIME_DIR=/tmp/runtime \
  MY_AI_BOX_REPO_ROOT=/repo \
  MY_AI_BOX_NONINTERACTIVE=1 \
  MY_AI_BOX_ASSISTANT=open-webui \
  MY_AI_BOX_DOMAIN=chat.example.com \
  MY_AI_BOX_EMAIL=you@example.com \
  MY_AI_BOX_PROVIDER=anthropic \
  MY_AI_BOX_API_KEY=sk-test-123 \
  MY_AI_BOX_EXTRAS=caddy \
  /repo/bin/my-ai-box install
'

echo "[e2e] asserting artifacts…"
multipass exec "${VM_NAME}" -- bash -c '
  set -e
  test -f /tmp/runtime/state.json || { echo "missing state.json" >&2; exit 1; }
  test -f /tmp/runtime/.env       || { echo "missing .env" >&2; exit 1; }
  test -f /tmp/runtime/compose.yml || { echo "missing compose.yml" >&2; exit 1; }
  test -f /tmp/runtime/compose.override.yml || { echo "missing compose.override.yml" >&2; exit 1; }
  stat -c "%a" /tmp/runtime/.env | grep -q "^600$" || { echo ".env not mode 0600" >&2; exit 1; }
  echo "[e2e] all assertions passed"
'
