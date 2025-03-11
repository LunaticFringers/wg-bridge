#!/bin/bash
# =============================================================================
# Script Name    : wg-bridge.sh
# Description    : Executes commands to handle Wireguard connections
# =============================================================================
# Usage          : ./wg-bridge.sh [connect, disconnect,list,status,path]
# =============================================================================
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/utils.sh"



# -----------------------------------------------------------------------------
# Purpose : Prints the usage message
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function usage(){
  echo "Usage: $(basename "$0") [OPTIONS] [COMMAND] <ARGUMENT>"
  echo ""
  echo "A tool to handle a Wireguard VPN"
  echo ""
  echo "Command"
  echo "  connect     [<arg>]  Connect to a specified resource (optional argument)"
  echo "  disconnect  [<arg>]  Disconnect from a specified resource (optional argument)"
  echo "  list                 List available resources"
  echo "  status               List active VPN"
  echo "  path                                "
  echo "              add      Add paths in the configuration file"
  echo "              delete   Remove a path from configuration file"
  echo "              list     List all paths"
  echo ""
  echo "Options:"
  echo "  -h, --help           Show this help message and exit"
  echo "  -v, --verbose        Enable verbose mode"
  echo ""
  echo "Example:"
  echo "  $(basename "$0") connect /path/to/server1.conf"
  echo "  $(basename "$0") disconnect    # Disconnect without specifying a resource"
  exit 1
}

# -----------------------------------------------------------------------------
# Purpose : Establish a connection to a VPN using a specific configuration
# Args    : Optionally takes the path to the configuration file
# Returns :
# -----------------------------------------------------------------------------
function connect(){
  local istoken=""
  local uri=""
  if [ "$1" != "" ]; then
    conf=$1
  else
    # get configurations connected
    IFS=$'\n' read -r -d '' -a avail < <(get_conf_by_status true; printf '\0')

    # Get all configurations
    all=($(find_configs))

    # Construct regex pattern safely
    pattern=$(printf "|%s" "${avail[@]}")
    pattern=${pattern:1}  # Remove leading "|"

    # Remove from all configurations those connected
    conf=$(list "$(printf "%s\n" "${all[@]}" | grep -v -E "^(${pattern})$")")
  fi
  if [ "$conf" != "" ]; then
    istoken=$(handle_token "$conf")
    out=$(sudo wg-quick up "$conf" 2>&1)
    if [ $? -ne 0 ]; then
      log_error "Connection to '$conf' failed"
      exit 4
    fi
    if [ $istoken ]; then
      uri=$(get_uri "$conf")
      set_connection_status "$conf" true
      xdg-open "$uri" > /dev/null 2>&1 &
    fi
  fi
}

# -----------------------------------------------------------------------------
# Purpose : Close the connection to a VPN using its specific configuration
# Args    : Optionally takes the path to the configuration file
# Returns :
# -----------------------------------------------------------------------------
function disconnect(){
  if [ "$1" != "" ]; then
    conf=$1
  else
    conf=$(list "$(get_conf_by_status true)")
  fi
  if [ "$conf" != "" ]; then
    out=$(sudo wg-quick down "$conf" 2>&1)
    if [ $? -ne 0 ]; then
      log_error "Disconnection from '$conf' failed"
      exit 4
    fi
    set_connection_status "$conf" false
  fi
}

# -----------------------------------------------------------------------------
# Purpose : Prints the list of configuration files available in the system
# Args    : show - used only to display the list
# Returns : The chosen configuration file path
# -----------------------------------------------------------------------------
function list(){
  if [[ "$1" == "show" ]]; then
    view_prompt "$(find_configs)"
  elif [ "$1" != "show" ] && [ "$1" != "" ]; then
    choose=$(view_prompt "$1")
  else
    choose=$(view_prompt "$(find_configs)")
  fi
  echo $choose | cut -d "|" -f2
}

# -----------------------------------------------------------------------------
# Purpose : Shows the status of the VPN connection
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function status(){
  if [ "$VERBOSE" ]; then
    sudo wg show all
  else
    sudo wg show interfaces
  fi
}

# -----------------------------------------------------------------------------
# Purpose : Adds a set of paths in the configuration file used to search the
#           VPN configurations
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function add_path(){
  add_dir_paths
}

# -----------------------------------------------------------------------------
# Purpose : Removes a path from configuration file used to search the VPN
#           configurations
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function remove_path(){
  mapfile -t items < <(load_paths)

  if [ ${#items[@]} -eq 0 ]; then
    log_info "No paths available"
    exit 0
  fi

   # Print the numbered list
  echo "Available paths:"
  for i in "${!items[@]}"; do
    echo "  $((i + 1)). ${items[i]}"
  done

  # Prompt the user to select a number
  echo
  read -rp "Enter the number of the path you want delete: " selection

  # Validate input and print the selected item
  if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection > 0 && selection <= ${#items[@]})); then
    # Get the selected item name
    item_to_remove="${items[$selection-1]}"

    # Remove the item from the JSON file using jq
    jq --arg item "$item_to_remove" 'del(.conf_path[] | select(. ==$item))' "$wgbconf" > "$wgbconf.tmp"
    sudo mv "$wgbconf.tmp" "$wgbconf"

    log_info "Item '$item_to_remove' has been removed from configuration file."
  else
    log_warn "Invalid selection."
  fi
}

# -----------------------------------------------------------------------------
# Purpose : Prints the available paths used to search the configuration file
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function list_path(){
  mapfile -t items < <(load_paths)
  # Print the numbered list
  if [ ${#items[@]} -eq 0 ]; then
    echo "No paths available"
    exit 0
  fi
  echo "Available paths:"
  for i in "${!items[@]}"; do
    echo "  $((i + 1)). ${items[i]}"
  done
}


###############################################################################
### MAIN
###############################################################################

if [ $# -eq 0 ]; then
  usage
  exit 2
fi

init_configuration

OPTIONS=vh
LONGOPTIONS=verbose,help
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")

if [ $? -ne 0 ]; then
  exit 2
fi

eval set -- "$PARSED"

while true; do
  case "$1" in
    -v|--verbose)
      export VERBOSE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

case "$1" in
  connect)
    connect "$2" || exit 1
    ;;
  disconnect)
    disconnect "$2" || exit 1
    ;;
  list)
    list "show" || exit 1
    ;;
  status)
    status || exit 1
    ;;
  path)
    shift
    case "$1" in
      add) add_path || exit 1
        ;;
      delete) remove_path || exit 1
        ;;
      list) list_path || exit 1
        ;;
      *)
        echo "Unknown option"
        exit 3
        ;;
    esac
    ;;
  *)
    echo "unknown command $1"
    usage
    exit 3
    ;;
esac
