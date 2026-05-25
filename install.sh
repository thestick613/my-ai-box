#!/usr/bin/env bash
set -euo pipefail

# install.sh — the bootstrapper.
# Fetched by: curl -fsSL https://raw.githubusercontent.com/thestick613/my-ai-box/v0.1.0/install.sh | bash
# (A shorter https://get.my-ai-box.sh redirect is on the roadmap.)
#
# Pipeline:
#   1. require_root
#   2. detect_distro (Ubuntu 22.04 / 24.04 / Debian 12 only)
#   3. install curl, git, jq, ca-certificates if missing
#   4. install Docker via get.docker.com if missing
#   5. clone github.com/thestick613/my-ai-box to /opt/my-ai-box (or use $MY_AI_BOX_DIR)
#   6. exec /opt/my-ai-box/bin/my-ai-box install "$@"

readonly MY_AI_BOX_REPO_URL="${MY_AI_BOX_REPO_URL:-https://github.com/thestick613/my-ai-box.git}"
readonly MY_AI_BOX_VERSION="${MY_AI_BOX_VERSION:-main}"
readonly MY_AI_BOX_DIR="${MY_AI_BOX_DIR:-/opt/my-ai-box}"

log() { printf '[my-ai-box] %s\n' "$*"; }
die() { printf '[my-ai-box] error: %s\n' "$*" >&2; exit 1; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "must be run as root (try: curl -fsSL https://raw.githubusercontent.com/thestick613/my-ai-box/v0.1.0/install.sh | sudo bash)"
  fi
}

detect_distro() {
  if [[ ! -r /etc/os-release ]]; then
    die "cannot detect distro: /etc/os-release missing"
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}-${VERSION_ID:-}" in
    ubuntu-22.04|ubuntu-24.04|debian-12)
      log "detected: ${ID} ${VERSION_ID}"
      ;;
    *)
      die "unsupported distro: ${ID:-?} ${VERSION_ID:-?} (supported: Ubuntu 22.04/24.04, Debian 12)"
      ;;
  esac
}

install_deps() {
  log "installing base dependencies (curl git jq ca-certificates)…"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y curl git jq ca-certificates
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "docker already installed: $(command -v docker)"
    return 0
  fi
  log "installing Docker via get.docker.com…"
  curl -fsSL https://get.docker.com | sh
}

clone_repo() {
  if [[ -d "${MY_AI_BOX_DIR}/.git" ]]; then
    log "repo exists at ${MY_AI_BOX_DIR}, fetching latest…"
    git -C "${MY_AI_BOX_DIR}" fetch --tags
    git -C "${MY_AI_BOX_DIR}" checkout "${MY_AI_BOX_VERSION}"
    git -C "${MY_AI_BOX_DIR}" pull --ff-only || true
  else
    log "cloning ${MY_AI_BOX_REPO_URL} (${MY_AI_BOX_VERSION}) to ${MY_AI_BOX_DIR}…"
    mkdir -p "$(dirname "${MY_AI_BOX_DIR}")"
    git clone --branch "${MY_AI_BOX_VERSION}" "${MY_AI_BOX_REPO_URL}" "${MY_AI_BOX_DIR}"
  fi
}

main() {
  require_root
  detect_distro
  install_deps
  install_docker
  clone_repo

  log "starting wizard…"
  # If this is a re-run on an existing install, jump into the menu.
  if [[ -f "${MY_AI_BOX_DIR}/state.json" ]]; then
    exec "${MY_AI_BOX_DIR}/bin/my-ai-box" menu "$@"
  else
    exec "${MY_AI_BOX_DIR}/bin/my-ai-box" install "$@"
  fi
}

main "$@"
