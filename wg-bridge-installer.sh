#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

user_home=$HOME
wgbconf="$user_home/.wgbconf.json"
tool_dir=/opt/wg-bridge
cmd=/usr/bin/wgb

function usage(){
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help       Show this help message and exit"
  # echo "  -v, --verbose              Enable verbose mode"
  echo "  -i, --install    Install WG-Bridge software"
  echo "  -u, --uninstall  Uninstall WG-Bridge software"
  echo ""
  exit 1
}

function install_dep(){
  sudo apt update -qq
  sudo apt install -qq -y wireguard yad jq
}

function install(){
  log_info "Installing dependency . . ."
  install_dep

  log_info "Installing wg-bridge . . ."
  if [ ! -d "$tool_dir" ]; then
    sudo mkdir $tool_dir
  fi
  sudo cp ./wg-bridge.sh ./utils.sh $tool_dir
  sudo chmod 755 $tool_dir/*
  if [ ! -f $cmd ]; then
    sudo ln -s $tool_dir/wg-bridge.sh $cmd
  fi

  log_info "Installing configuration . . ."

  if [ ! -f "$wgbconf" ]; then
    log_warn "Enter the path to configuration files (or empty line to finish)"
    while true; do
      # Get the directory path from the user
      read -rp "Path: " dir

      # If the user pressed Enter without typing anything, stop the loop
      if [[ -z "$dir" ]]; then
        break
      fi

      # Append the directory path to the string, separated by a comma
      if [[ -z "$directories" ]]; then
        directories="\"$dir\""
      else
        directories="$directories,\"$dir\""
      fi
    done
    echo -e "{\n\t\"config_path\": [$directories]\n}" > "$wgbconf"
  fi

  log_info "Done"
}

if [ $# == 0 ]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--install)
      install || exit 1
      ;;
    -u|--uninstall)
      uninstall || exit 1
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done
