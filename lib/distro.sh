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

# print_system_info <runtime_dir> [os_release_path] [cpuinfo_path] [meminfo_path]
# Prints a multi-line banner to stdout with OS, CPU, RAM, Disk free.
# Public IP is best-effort via the existing public_ip helper (printed only if
# `public_ip` is defined, which it is when sourced from bin/my-ai-box).
print_system_info() {
  local runtime_dir="$1"
  local os_release_path="${2:-/etc/os-release}"
  local cpuinfo_path="${3:-/proc/cpuinfo}"
  local meminfo_path="${4:-/proc/meminfo}"

  local distro cpu ram disk parent_dir
  distro=$(detect_distro "${os_release_path}" 2>/dev/null || echo "unknown")
  cpu=$(detect_cpu_count "${cpuinfo_path}")
  ram=$(detect_ram_gb "${meminfo_path}")
  parent_dir=$(dirname "${runtime_dir}")
  disk=$(detect_disk_free_gb "${parent_dir}")

  echo "[my-ai-box] OS:        ${distro}"
  echo "[my-ai-box] CPU:       ${cpu} vCPU"
  echo "[my-ai-box] RAM:       ${ram} GB"
  echo "[my-ai-box] Disk:      ${disk} GB free at ${parent_dir}"
  # Public IP best-effort: only printed if helper is loaded AND fetch succeeds.
  if declare -F public_ip >/dev/null 2>&1; then
    local ip
    ip=$(public_ip 2>/dev/null) && echo "[my-ai-box] Public IP: ${ip}" || true
  fi
}

# check_minimums <runtime_dir> [cpuinfo_path] [meminfo_path]
# Warns to stderr if CPU/RAM/Disk are below operational floors.
# Returns 0 if all good, 1 if any warning was printed.
check_minimums() {
  local runtime_dir="$1"
  local cpuinfo_path="${2:-/proc/cpuinfo}"
  local meminfo_path="${3:-/proc/meminfo}"

  local cpu ram disk parent_dir
  cpu=$(detect_cpu_count "${cpuinfo_path}")
  ram=$(detect_ram_gb "${meminfo_path}")
  parent_dir=$(dirname "${runtime_dir}")
  disk=$(detect_disk_free_gb "${parent_dir}")

  local warned=0

  if [[ "${cpu}" =~ ^[0-9]+$ ]] && (( cpu < 2 )); then
    echo "[my-ai-box] ⚠ CPU: ${cpu} vCPU (recommended 2+). Install will be slow." >&2
    warned=1
  fi
  if [[ "${ram}" =~ ^[0-9.]+$ ]] && awk -v r="${ram}" 'BEGIN { exit !(r < 2) }'; then
    echo "[my-ai-box] ⚠ RAM: ${ram} GB (minimum 2, recommended 4). Open WebUI may OOM at startup." >&2
    warned=1
  fi
  if [[ "${disk}" =~ ^[0-9]+$ ]] && (( disk < 5 )); then
    echo "[my-ai-box] ⚠ Disk free: ${disk} GB (minimum 5). Docker image pulls may fail." >&2
    warned=1
  fi
  return ${warned}
}
