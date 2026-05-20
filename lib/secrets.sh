#!/usr/bin/env bash
# lib/secrets.sh — write, read, and shred secrets in a .env file.
# Sourced, not executed.

# write_env_var <env_file> <key> <value>
# Writes KEY=VALUE to env_file, replacing any existing line for KEY.
# Creates the file with mode 0600 if it doesn't exist.
write_env_var() {
  local env_file="$1" key="$2" value="$3"
  if [[ ! -f "${env_file}" ]]; then
    : > "${env_file}"
    chmod 600 "${env_file}"
  fi
  # Strip any existing line for this key.
  local tmp
  tmp=$(mktemp "${env_file}.tmp.XXXXXX")
  chmod 600 "${tmp}"
  grep -v "^${key}=" "${env_file}" > "${tmp}" || true
  printf '%s=%s\n' "${key}" "${value}" >> "${tmp}"
  mv "${tmp}" "${env_file}"
  chmod 600 "${env_file}"
}

# read_env_var <env_file> <key>
# Echoes the VALUE for KEY, or returns 1 if not present.
read_env_var() {
  local env_file="$1" key="$2"
  if [[ ! -f "${env_file}" ]]; then
    return 1
  fi
  local line
  line=$(grep -E "^${key}=" "${env_file}" | tail -n1) || return 1
  if [[ -z "${line}" ]]; then
    return 1
  fi
  echo "${line#"${key}="}"
}
