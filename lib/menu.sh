#!/usr/bin/env bash
# lib/menu.sh — terminal prompts and menu rendering for the wizard.
# Sourced, not executed.

# prompt_choice <prompt> <option1> [<option2> ...]
# Prints the numbered options, reads a number from stdin (default 1),
# echoes the chosen option's text on stdout. Re-prompts on invalid input.
prompt_choice() {
  local prompt="$1"; shift
  local -a opts=("$@")
  local count=${#opts[@]}
  if [[ $count -eq 0 ]]; then
    echo "prompt_choice: no options" >&2
    return 2
  fi

  echo "${prompt}" >&2
  local i
  for ((i = 0; i < count; i++)); do
    printf "  %d) %s\n" "$((i + 1))" "${opts[$i]}" >&2
  done

  local choice
  while :; do
    printf "Choice [1]: " >&2
    IFS= read -r choice || choice=""
    [[ -z "${choice}" ]] && choice=1
    if [[ "${choice}" =~ ^[0-9]+$ ]] \
       && (( choice >= 1 )) && (( choice <= count )); then
      echo "${opts[$((choice - 1))]}"
      return 0
    fi
    echo "invalid choice: ${choice}" >&2
  done
}

# prompt_yesno <prompt> <default Y|N>
# Returns 0 if user answered yes, 1 if no.
prompt_yesno() {
  local prompt="$1"
  local default="${2:-N}"
  local hint
  if [[ "${default}" =~ ^[Yy]$ ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  local ans
  printf "%s %s: " "${prompt}" "${hint}" >&2
  IFS= read -r ans || ans=""
  [[ -z "${ans}" ]] && ans="${default}"
  [[ "${ans}" =~ ^[Yy]$ ]]
}

# prompt_string <prompt> <default>
# Reads a single line from stdin, echoes it. Returns default if empty.
prompt_string() {
  local prompt="$1"
  local default="${2:-}"
  local ans
  if [[ -n "${default}" ]]; then
    printf "%s [%s]: " "${prompt}" "${default}" >&2
  else
    printf "%s: " "${prompt}" >&2
  fi
  IFS= read -r ans || ans=""
  [[ -z "${ans}" ]] && ans="${default}"
  echo "${ans}"
}

# prompt_secret <prompt>
# Reads a single line from stdin WITHOUT echoing characters. Echoes value on stdout.
prompt_secret() {
  local prompt="$1"
  local ans
  printf "%s (input hidden): " "${prompt}" >&2
  IFS= read -rs ans || ans=""
  echo >&2  # newline after hidden input
  echo "${ans}"
}
