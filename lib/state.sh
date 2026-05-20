#!/usr/bin/env bash
# lib/state.sh — read/write /opt/my-ai-box/state.json.
# Sourced, not executed.
# Requires: jq.

STATE_SCHEMA_VERSION=1

# _state_init <state_file>
# Ensures the file exists and has the baseline structure.
_state_init() {
  local state_file="$1"
  if [[ ! -f "${state_file}" ]]; then
    jq -n --argjson v "${STATE_SCHEMA_VERSION}" \
      '{schema_version: $v, extras: [], created_at: now | todate}' \
      > "${state_file}"
  fi
}

# write_state <state_file> key=value [key=value ...]
# Sets the given keys atomically. Preserves other fields.
write_state() {
  local state_file="$1"; shift
  _state_init "${state_file}"
  local jq_filter='.' arg_idx=0
  local -a jq_args=()
  for kv in "$@"; do
    local k="${kv%%=*}" v="${kv#*=}"
    jq_args+=(--arg "k${arg_idx}" "${k}" --arg "v${arg_idx}" "${v}")
    # shellcheck disable=SC2016
    jq_filter+=" | .[\$k${arg_idx}] = \$v${arg_idx}"
    arg_idx=$((arg_idx + 1))
  done
  local tmp
  tmp=$(mktemp "${state_file}.tmp.XXXXXX")
  jq "${jq_args[@]}" "${jq_filter}" "${state_file}" > "${tmp}"
  mv "${tmp}" "${state_file}"
}

# read_state <state_file> <key>
# Echoes the value of the given top-level key, or returns 1 if missing/null.
read_state() {
  local state_file="$1" key="$2"
  [[ -f "${state_file}" ]] || return 1
  local val
  val=$(jq -r --arg k "${key}" '.[$k] // empty' "${state_file}")
  if [[ -z "${val}" ]]; then return 1; fi
  echo "${val}"
}

# add_extra <state_file> <extra_name>
# Adds to .extras (deduped, sorted alphabetically).
add_extra() {
  local state_file="$1" name="$2"
  _state_init "${state_file}"
  local tmp
  tmp=$(mktemp "${state_file}.tmp.XXXXXX")
  jq --arg n "${name}" '.extras = ((.extras + [$n]) | unique)' \
    "${state_file}" > "${tmp}"
  mv "${tmp}" "${state_file}"
}

# remove_extra <state_file> <extra_name>
# Removes the given extra from .extras.
remove_extra() {
  local state_file="$1" name="$2"
  [[ -f "${state_file}" ]] || return 0
  local tmp
  tmp=$(mktemp "${state_file}.tmp.XXXXXX")
  jq --arg n "${name}" '.extras = (.extras - [$n])' \
    "${state_file}" > "${tmp}"
  mv "${tmp}" "${state_file}"
}
