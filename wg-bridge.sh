#!/bin/bash

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/utils.sh"


function usage(){
  echo "Usage: $(basename "$0") [OPTIONS] <ARGUMENT>"
  echo ""
  echo "A tool to connect to a Wireguard VPN"
  echo ""
  echo "Options:"
  echo "  -h, --help                 Show this help message and exit"
  echo "  -v, --verbose              Enable verbose mode"
  echo "  -c, --connect     [<arg>]  Connect to a specified resource (optional argument)"
  echo "  -d, --disconnect  [<arg>]  Disconnect from a specified resource (optional argument)"
  echo "  -l, --list                 List available resources"
  echo "  -s, --status               List active VPN"
  echo ""
  echo "Example:"
  echo "  $(basename "$0") -c /path/to/server1.conf"
  echo "  $(basename "$0") -d    # Disconnect without specifying a resource"
  exit 1
}


function connect(){
  if [ "$1" != "" ]; then
    conf=$1
  else
    conf=$(list)
  fi
  if [ "$conf" != "" ]; then
    sudo wg-quick up "$conf"
  fi
}

function disconnect(){
  if [ "$1" != "" ]; then
    conf=$1
  else
    conf=$(list)
  fi
  if [ "$conf" != "" ]; then
    wg-quick down "$conf"
  fi
}

function list(){
  choose=$(view_prompt "$(find_configs)")
  if [[ "$1" == "show" ]]; then
    exit 0
  fi
  echo $choose | cut -d "|" -f2
}

function status(){
  if [ "$VERBOSE" ]; then
    sudo wg show all
  else
    sudo wg show interfaces
  fi
}

if [[ $# == 0 ]]; then
  usage
fi

get_configuration
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose)
      export VERBOSE=true
      ;;
    -c|--connect)
      shift
      connect "$1" || exit 1
      ;;
    -d|--disconnect)
      shift
      disconnect "$1" || exit 1
      ;;
    -l|--list)
      list "show" || exit 1
      ;;
    -s|--status)
      status || exit 1
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done
