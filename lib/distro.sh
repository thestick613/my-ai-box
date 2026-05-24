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

# install_pkg <pkg> [<pkg> ...]
# Installs one or more system packages using the distro's package manager.
# Currently supports apt-based distros (Ubuntu, Debian).
install_pkg() {
  if [[ $# -eq 0 ]]; then
    echo "install_pkg: no packages given" >&2
    return 1
  fi
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

# install_docker
# Installs Docker Engine via get.docker.com if `docker` is not on PATH.
# Idempotent: prints a message and returns 0 if Docker is already installed.
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "docker already installed: $(command -v docker)"
    return 0
  fi
  echo "installing Docker via get.docker.com…"
  curl -fsSL https://get.docker.com | sh
}

# detect_cpu_count [cpuinfo_path]
# Returns the number of vCPUs as a plain integer, or "1" if undetectable.
detect_cpu_count() {
  local cpuinfo="${1:-/proc/cpuinfo}"
  if command -v nproc >/dev/null 2>&1; then
    nproc 2>/dev/null && return 0
  fi
  if [[ -r "${cpuinfo}" ]]; then
    grep -c '^processor' "${cpuinfo}"
    return 0
  fi
  echo "1"
}

# detect_ram_gb [meminfo_path]
# Echoes total RAM in GB as a single decimal (e.g., "4.0"), or "?" if undetectable.
detect_ram_gb() {
  local meminfo="${1:-/proc/meminfo}"
  if [[ ! -r "${meminfo}" ]]; then
    echo "?"
    return 0
  fi
  awk '/^MemTotal:/ { printf "%.1f\n", $2 / 1024 / 1024; found=1; exit } END { if (!found) print "?" }' "${meminfo}"
}

# detect_disk_free_gb <path>
# Echoes free disk space in GB at the given path (parent of runtime dir, typically).
detect_disk_free_gb() {
  local path="${1:-/}"
  # `df -B 1G` is GNU; tests mock df entirely so this works portably.
  df -B 1G "${path}" 2>/dev/null | awk 'NR==2 { print $4 }' || echo "?"
}
