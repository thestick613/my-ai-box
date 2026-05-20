#!/usr/bin/env bash
# lib/distro.sh — distro detection and package install helpers.
# This file is meant to be sourced, not executed.

# detect_distro [os_release_path]
# Echoes a normalized distro tag like "ubuntu-24.04" or "debian-12".
# Returns 0 on success, 1 on unsupported distro, 2 if os-release is missing.
detect_distro() {
  local release_path="${1:-/etc/os-release}"

  if [[ ! -r "${release_path}" ]]; then
    echo "cannot detect distro: ${release_path} not readable" >&2
    return 2
  fi

  local id version
  # shellcheck disable=SC1090
  id=$(. "${release_path}"; echo "${ID:-}")
  # shellcheck disable=SC1090
  version=$(. "${release_path}"; echo "${VERSION_ID:-}")

  case "${id}-${version}" in
    ubuntu-22.04|ubuntu-24.04|debian-12)
      echo "${id}-${version}"
      return 0
      ;;
    *)
      echo "unsupported distro: ${id} ${version}" >&2
      return 1
      ;;
  esac
}

# require_root
# Exits non-zero with a helpful message if the current process isn't root.
# Uses `id -u` so the check is mockable in tests via PATH injection.
require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "must be run as root (try: sudo $0 \"\$@\")" >&2
    return 1
  fi
  return 0
}
