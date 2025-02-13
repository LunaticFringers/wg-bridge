#!/bin/bash

# Autocomplete for the Wireguard VPN connect/disconnect script
user_home=$HOME
wgbconf="$user_home/.wgbconf.json"

get_configuration(){
  while IFS= read -r item; do
    DIRS+=("$item")
  done < <(jq -r '.config_path[]' "$wgbconf")
}

find_configs(){
  get_configuration
  DIRS=("${DIRS[@]}")
  sudo find "${DIRS[@]}" -type f -name "*.conf" 2>/dev/null
}

_lovpn_autocomplete() {
  local cur prev opts
  COMPREPLY=()  # Initialize COMPREPLY array

  # Define the possible options for the script
  opts="-h --help -c --connect -d --disconnect -l --list -s --status"

  # The current word (argument) being typed
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ ${COMP_CWORD} -eq 1 ]]; then
    mapfile -t COMPREPLY < <(compgen -W "$opts" -- "$cur")
    return 0
  fi

  # Handle specific cases based on previous word
  case "$prev" in
    -c|--connect|-d|--disconnect)
      mapfile -t COMPREPLY < <(find_configs)  # Suggest example resources
      return 0
      ;;
  esac

  return 0
}

# Register the autocomplete function
complete -F _wgb_autocomplete wgb
