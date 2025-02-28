#!/bin/bash

export CYAN="\e[36m"
export YELLOW="\e[33m"
export RED="\e[31m"
export NC="\e[0m"

export user_home=$HOME
export wgbconf="$user_home/.wgbconf.json"
export DIRS=("/etc/wireguard")
export token=false
export token_uri=""


function log_error(){
  echo -e "$RED$1$NC"
}
function log_warn(){
  echo -e "$YELLOW$1$NC"
}
function log_info(){
  echo -e "$CYAN$1$NC"
}

function get_error_msg(){
  errors="$(jq -r '.error_codes' "$wgbconf")"

  echo $errors | jq -r "$1"
}

function get_configuration(){
  if [ -f "$wgbconf" ]; then
    while IFS= read -r item; do
      DIRS+=("$item")
    done < <(jq -r '.conf_path[]' "$wgbconf")
    token=$(jq -r '.token' "$wgbconf")
    token_uri=$(jq -r '.token_uri' "$wgbconf")
  else
    log_error "{000} Something goes wrong. Reinstall the tool."
    exit 1
  fi
}

function view_prompt(){
  local paths=()
  local names=()

  for i in $@; do
    paths+=("$i")
    names+=("$(basename "$i")")
  done

  yad --list --title="Select a Wireguard configuration" \
        --column="Name" --column="Path" --width=500 --height=400 --multiple $(for i in "${!paths[@]}"; do echo -e "${names[$i]}"; echo -e "${paths[$i]}"; done)
}

function find_configs(){
  sudo find "${DIRS[@]}" -type f -name "*.conf" 2>/dev/null
}

function handle_token() {
  local conf="$1"
  local istoken=""
  local uri=""

  # Extract JSON object for the given path
  # confset=$(jq --arg value "$conf" '.confs[] | select(.path==$value)' "$wgbconf")
  confset=$(jq --arg value "$conf" '.confs // [] | map(select(.path==$value)) | first' "$wgbconf")


  if [[ -n "$confset" ]]; then
    # Extract token from JSON (force raw output to avoid quotes)
    istoken=$(echo "$confset" | jq -r '.token')
    # If no token exists, prompt the user
    if [[ -z "$istoken" || "$istoken" == "null" ]]; then
      read -rp "Is it necessary to enter a token to connect? [y/N] " token
      case "${token,,}" in
        "y"|"yes")
          istoken=true
          read -rp "Insert URI of 2FA: " uri
          ;;
        *)
          istoken=false
          uri=""
          ;;
      esac
      # Update JSON file
      jq --arg path "$conf" --argjson token "$istoken" --arg uri "$uri" \
        '.confs += [{"path": $path, "token": $token, "uri": $uri}]' "$wgbconf" | \
      sudo tee "$wgbconf.tmp" > /dev/null

      # Move temp file and set permissions
      sudo mv "$wgbconf.tmp" "$wgbconf"
      sudo chown "$USER:$USER" "$wgbconf"
      sudo chmod 644 "$wgbconf"
    fi
    echo $istoken
  fi
}


function get_uri(){
  local conf="$1"
  uri=$(jq -r --arg value "$conf" '.confs[] | select(.path==$value) | .uri' "$wgbconf")
  echo $uri
}


function add_dir_paths(){
  log_warn "Enter the path to configuration files (or empty line to finish)"
  while true; do
    # Get the directory path from the user
    read -rp "Path: " dir

    # If the user pressed Enter without typing anything, stop the loop
    if [[ -z "$dir" ]]; then
      break
    fi

    # Append the directory path to the string, separated by a comma
    directories+=("$dir")
  done

  jsonarray=$(printf '%s\n' "${directories[@]}" | jq -R . | jq -s .)

  jq --argjson paths "$jsonarray" '.conf_path += $paths' $wgbconf > $wgbconf.tmp
  sudo mv $wgbconf.tmp $wgbconf
  sudo chown $USER:$USER $wgbconf
  sudo chmod 644 $wgbconf
}


function load_paths(){
  # Read JSON array into a Bash array
  mapfile -t items < <(jq -r '.conf_path[]' $wgbconf)

  for item in "${items[@]}"; do
    echo "$item"
  done
}

function get_conf_by_status(){
  local status="$1"
  mapfile -t connected < <(jq -r --argjson stat "$status" '.confs[] | select((.connected == $stat) or ($stat == false and .connected == null)) | .path' "$wgbconf")

  for item in "${connected[@]}"; do
    echo "$item"
  done
}


function set_connection_status(){
  local conf="$1"
  local status=$2
  jq --arg target "$conf" --argjson status "$status" '(.confs[] | select(.path==$target)) += {connected: $status}' "$wgbconf" > $wgbconf.tmp

  mv $wgbconf.tmp $wgbconf
}
