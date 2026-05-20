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
