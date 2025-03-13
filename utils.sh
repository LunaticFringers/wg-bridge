#!/bin/bash
# =============================================================================
# Script Name    : utils.sh
# Description    : Set of utility functions used by various other scripts
# =============================================================================
# Usage          :
# =============================================================================

export CYAN="\e[36m"
export YELLOW="\e[33m"
export RED="\e[31m"
export NC="\e[0m"

export user_home=$HOME
export DIRS=("/etc/wireguard")
export token=false
export token_uri=""
procerrorlog=$(mktemp)

conf=".wgbconf.json" # not exporting this because it's only used during the installation procedure
export wgbconf="$user_home/$conf"

# -----------------------------------------------------------------------------
# Purpose : Prints in STDOUT an error message
# Args    : Message to print
# Returns :
# -----------------------------------------------------------------------------
function print_error(){
  echo -e "$RED$1$NC"
}

# -----------------------------------------------------------------------------
# Purpose : Prints in STDOUT a warning message
# Args    : Message to print
# Returns :
# -----------------------------------------------------------------------------
function print_warn(){
  echo -e "$YELLOW$1$NC"
}

# -----------------------------------------------------------------------------
# Purpose : Prints in STDOUT an information message
# Args    : Message to print
# Returns :
# -----------------------------------------------------------------------------
function print_info(){
  echo -e "$CYAN$1$NC"
}

#------------------------------------------------------------------------------
# Purpose : Prints in the default log file a verbose output to help the
#           debugging
# Args    : The exit status of the previous process
# Returns : The exit status of the previous process
#------------------------------------------------------------------------------
function log_to_file(){
  local date
  while IFS= read -r line; do
    date=$(date '+%d-%m-%Y %H:%M:%S')
    echo "[$date] :: $line"
  done < $procerrorlog >> "/var/log/wg-bridge/wgb.log"

  return $1 # return the exit status of previous process
}

# -----------------------------------------------------------------------------
# Purpose : Get error message by its code
# Args    : Error Code
# Returns : Error Message
# -----------------------------------------------------------------------------
function get_error_msg(){
  errors="$(jq -r '.error_codes' "$wgbconf")"

  echo $errors | jq -r "$1"
}

# -----------------------------------------------------------------------------
# Purpose : Set the environment using the configuration found in the
#           configuration file ".wgbconf.json"
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function init_configuration(){
  if [ -f "$wgbconf" ]; then
    while IFS= read -r item; do
      DIRS+=("$item")
    done < <(jq -r '.conf_path[]' "$wgbconf")
    token=$(jq -r '.token' "$wgbconf")
    token_uri=$(jq -r '.token_uri' "$wgbconf")
  else
    print_error "{000} Something goes wrong. Reinstall the tool."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Purpose : Open a YAD window with a list of VPN configurations
# Args    : Array of VPN configrations to display
# Returns :
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Purpose : Searches the VPN configurations in the listed path in
#           '.wgbconf.json'
# Args    :
# Returns : The list of paths to VPN configurations
# -----------------------------------------------------------------------------
function find_configs(){
  sudo find "${DIRS[@]}" -type f -name "*.conf" 2>$procerrorlog ; log_to_file $?
}

# -----------------------------------------------------------------------------
# Purpose : Handles 2FA for connection that require it
# Args    : VPN configuration path
# Returns : true if connection use 2FA, false otherwise
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Purpose : Get the URI to enter PIN for 2FA
# Args    : VPN configuration path
# Returns : The URI
# -----------------------------------------------------------------------------
function get_uri(){
  local conf="$1"
  uri=$(jq -r --arg value "$conf" '.confs[] | select(.path==$value) | .uri' "$wgbconf")
  echo $uri
}

# -----------------------------------------------------------------------------
# Purpose : Adds a set of paths in the configuration file used to search the
#           VPN configurations
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function add_dir_paths(){
  print_warn "Enter the path to configuration files (or empty line to finish)"
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

  # Only add the directories if the array is not empty, otherwise create an empty array
  if [ ${#directories[@]} -gt 0 ]; then
    jsonarray=$(printf '%s\n' "${directories[@]}" | jq -R . | jq -s .)
  else
    jsonarray="[]"
  fi

  jq --argjson paths "$jsonarray" '.conf_path += $paths' $conf > $wgbconf.tmp
  sudo mv $wgbconf.tmp $wgbconf
  sudo chown $USER:$USER $wgbconf
  sudo chmod 644 $wgbconf
}

# -----------------------------------------------------------------------------
# Purpose : Reads the json file to get the paths to search for VPN
#           configurations
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function load_paths(){
  # Read JSON array into a Bash array
  mapfile -t items < <(jq -r '.conf_path[]' $wgbconf)

  for item in "${items[@]}"; do
    echo "$item"
  done
}

# -----------------------------------------------------------------------------
# Purpose : Get the VPN configurations path by their status
# Args    : status
# Returns : array with the VPN configurations path
# -----------------------------------------------------------------------------
function get_conf_by_status(){
  local status="$1"
  mapfile -t connected < <(jq -r --argjson stat "$status" '.confs[] | select((.connected == $stat) or ($stat == false and .connected == null)) | .path' "$wgbconf")

  for item in "${connected[@]}"; do
    echo "$item"
  done
}

# -----------------------------------------------------------------------------
# Purpose : Set the VPN configuration path and its status
# Args    : status, configuration path
# Returns :
# -----------------------------------------------------------------------------
function set_connection_status(){
  local conf="$1"
  local status=$2
  jq --arg target "$conf" --argjson status "$status" '(.confs[] | select(.path==$target)) += {connected: $status}' "$wgbconf" > $wgbconf.tmp

  mv $wgbconf.tmp $wgbconf
}
