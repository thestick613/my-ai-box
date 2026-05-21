#!/usr/bin/env bash
# lib/compose.sh — render and operate Docker Compose files for my-ai-box.
# Sourced, not executed.

# compose_render <repo_root> <runtime_dir> <assistant_name> <extras_space_separated>
# Copies assistants/<assistant>/compose.yml to <runtime_dir>/compose.yml
# and concatenates extras/<extra>/compose-overlay.yml into
# <runtime_dir>/compose.override.yml. Removes the override when extras is empty.
compose_render() {
  local repo="$1" runtime="$2" assistant="$3" extras="$4"

  local base="${repo}/assistants/${assistant}/compose.yml"
  if [[ ! -f "${base}" ]]; then
    echo "compose_render: assistant base not found: ${base}" >&2
    return 1
  fi
  cp "${base}" "${runtime}/compose.yml"

  local override="${runtime}/compose.override.yml"
  if [[ -z "${extras}" ]]; then
    rm -f "${override}"
    return 0
  fi

  : > "${override}"
  local first=1
  for ex in ${extras}; do
    local snippet="${repo}/extras/${ex}/compose-overlay.yml"
    if [[ ! -f "${snippet}" ]]; then
      echo "compose_render: extra overlay not found: ${snippet}" >&2
      return 1
    fi
    if [[ ${first} -eq 1 ]]; then
      cat "${snippet}" >> "${override}"
      first=0
    else
      # Subsequent overlays: strip leading 'services:' to avoid double-keys.
      awk 'BEGIN{started=0} /^services:/{started=1; next} {if (started) print}' \
        "${snippet}" >> "${override}"
    fi
  done
}

# compose_up <runtime_dir> <env_file>
# Brings up the stack with optional override.
compose_up() {
  local runtime="$1" env_file="$2"
  local -a args=(-f "${runtime}/compose.yml")
  [[ -f "${runtime}/compose.override.yml" ]] && args+=(-f "${runtime}/compose.override.yml")
  args+=(--env-file "${env_file}")
  ( cd "${runtime}" && docker compose "${args[@]}" up -d )
}

# compose_down <runtime_dir>
# Tears down the stack and removes orphaned containers.
compose_down() {
  local runtime="$1"
  ( cd "${runtime}" && docker compose down --remove-orphans )
}
