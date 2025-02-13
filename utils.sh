#!/bin/bash

export CYAN="\e[36m"
export YELLOW="\e[33m"
export RED="\e[31m"
export NC="\e[0m"

function log_error(){
  echo -e "$RED$1$NC"
}
function log_warn(){
  echo -e "$YELLOW$1$NC"
}
function log_info(){
  echo -e "$CYAN$1$NC"
}

export user_home=$HOME
export wgbconf="$user_home/.wgbconf.json"
export DIRS=("/etc/wireguard")

function get_configuration(){
  while IFS= read -r item; do
    DIRS+=("$item")
  done < <(jq -r '.config_path[]' "$wgbconf")
}

function view_prompt(){
  local data=("$@")

  printf "%s\n" "${data[@]}" | yad --list --title="Select a Wireguard configuration" \
        --column="Files" --width=500 --height=400 --separator=" " --multiple
}

function find_configs(){
  DIRS=("${@:-${DIRS[@]}}")
  sudo find "${DIRS[@]}" -type f -name "*.conf" 2>/dev/null
}
