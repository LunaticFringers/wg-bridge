#!/bin/bash

# Autocomplete for Wireguard VPN script
user_home=$HOME
wgbconf="$user_home/.wgbconf.json"
DIRS=("/etc/wireguard")

# Load user-configured paths
init_configuration(){
  while IFS= read -r item; do
    DIRS+=("$item")
  done < <(jq -r '.conf_path[]' "$wgbconf" 2>/dev/null)
}

# Find available configurations
find_configs(){
  init_configuration
  sudo find "${DIRS[@]}" -type f -name "*.conf" 2>/dev/null
}

_wgb_autocomplete() {
  local cur prev opts sub_opts flags confs
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Define available commands
  opts="connect disconnect list status path"

  # Sub-options for "path"
  sub_opts="add list delete"

  # Global options
  flags="-v --version -h --help"

  # Load configurations into an array
  confs=$(find_configs)

  if [[ "$prev" == "path" ]]; then
    # Provide sub-options for "path"
    mapfile -t COMPREPLY < <(compgen -W "$sub_opts" -- "$cur")
    return 0
  elif [[ "$prev" == "connect" || "$prev" == "disconnect" ]]; then
    # Provide list of config files
    mapfile -t COMPREPLY < <(compgen -W "${confs[*]}" -- "$cur")
    return 0
  else
    # Default: Suggest commands and global options
    mapfile -t COMPREPLY < <(compgen -W "$opts $flags" -- "$cur")
    return 0
  fi


}

# Register the autocomplete function
complete -F _wgb_autocomplete wgb
