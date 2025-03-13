#!/bin/bash
# =============================================================================
# Script Name    : wg-bridge-installer.sh
# Description    : Installs the wg-brige software
# =============================================================================
# Usage          : ./wg-bridge-installer.sh [install, uninstall]
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

user_home=$HOME
tool_dir=/opt/wg-bridge
cmd=/usr/bin/wgb
logpath=/var/log/wg-bridge


# -----------------------------------------------------------------------------
# Purpose : Prints the usage message
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function usage(){
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help       Show this help message and exit"
  echo "  install          Install WG-Bridge software"
  echo "    -u, --update   Update WG-Bridge software"
  echo "  uninstall        Uninstall WG-Bridge software"
  echo ""
  exit 1
}

# -----------------------------------------------------------------------------
# Purpose : Installs the software dependences
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function install_dep(){
  sudo apt update -qq
  sudo apt install -qq -y wireguard yad jq
}

# -----------------------------------------------------------------------------
# Purpose : Installs the all scripts
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function _install_sw(){
  if [ "$update" == false ]; then
    print_info "Installing wg-bridge . . ."
  else
    print_info "Updating wg-bridge . . ."
  fi
  if [ ! -d "$tool_dir" ]; then
    sudo mkdir $tool_dir
  fi
  sudo cp -f ./wg-bridge.sh ./utils.sh ./version $tool_dir
  sudo chmod 755 $tool_dir/*
  if [ ! -f $cmd ]; then
    sudo ln -s $tool_dir/wg-bridge.sh $cmd
  fi

  if [ ! -d "$logpath" ]; then
    sudo mkdir "$logpath"
    sudo chown $USER:$USER "$logpath"
    sudo chmod 770 "$logpath"
  fi
}

# -----------------------------------------------------------------------------
# Purpose : Entry point of installation process
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function install(){
  print_info "Installing dependency . . ."
  install_dep

  if [ ! -f "$wgbconf" ]; then
    _install_sw

    print_info "Installing configuration . . ."

    add_dir_paths
  else
    if [ -f "$tool_dir/version" ]; then
      if ([ "$(md5sum < "$tool_dir/version")" != "$(md5sum < ./version)" ] && [ "$update" == "true" ]) || [ "$force" == "true" ]; then
        _install_sw
        mv "$wgbconf" "$wgbconf.bak"
        jq --slurpfile customer "$wgbconf.bak" '.conf_path |= (. + $customer[0].conf_path)' "$conf" > "$wgbconf"
        jq --slurpfile customer "$wgbconf.bak" '.confs |= (. + $customer[0].confs)' "$wgbconf" > "$wgbconf.tmp"
        mv "$wgbconf.tmp" "$wgbconf"
      else
        print_warn "Software already installed"
        exit 1
      fi
    fi
  fi

  sudo chown $USER:$USER "$wgbconf"
  sudo chmod 644 "$wgbconf"

  sudo cp "wg-bridge-completion.sh" "/etc/bash_completion.d/"
  sudo chmod 755 "/etc/bash_completion.d/wg-bridge-completion.sh"

  print_info "Done"
}


# -----------------------------------------------------------------------------
# Purpose : Entry point of the uninstallation process
# Args    :
# Returns :
# -----------------------------------------------------------------------------
function uninstall(){
  print_info "Uninstalling wg-bridge . . ."
  if [ -f $wgbconf ]; then
    sudo rm $wgbconf
  fi
  if [ -d $tool_dir ]; then
    sudo rm -rf $tool_dir
  fi
  if [ -f "/usr/bin/wgb" ]; then
    sudo rm /usr/bin/wgb
  fi
  if [ -f "/etc/bash_completion.d/wg-bridge-completion.sh" ]; then
    sudo rm "/etc/bash_completion.d/wg-bridge-completion.sh"
  fi
  print_info "Done"
}

###############################################################################
### MAIN
###############################################################################

if [ $# == 0 ]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    install)
      shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          -u|--update)
            update=true
            shift
            ;;
          -f|--force)
            force=true
            shift
            ;;
          *)
            update=false
            break
            ;;
        esac
      done
      install || exit 1
      ;;
    uninstall)
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
