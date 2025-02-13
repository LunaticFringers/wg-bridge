# WG-Bridge

_Simplified Wireguard VPN handler for Debian &amp; derivates_

## Introduction

WG-Bridge is a simple VPN management tool that allows you to easily connect,
disconnect, list, and check the status of your VPN connections.

## Installation

Run the `wg-bridge-installer.sh` with option `-i` or `--install` to install
the main software.

## Usage

After installation, you can launch `wgb` via the command line with the following
options:

### Commands

- **Connect**:
To connect to the VPN, use the `-c` or `--connect` option
- **Disconnect**:
  To disconnect from the VPN, use the `-d` or `--disconnect` option
- **List**:
  To list available VPN connections, use the `-l` or `--list` option
- **Status**:
  To check the current status of the VPN connection, use the `-s` or `--status`

The connect and disconnect options also accept an optional argument which is the
full path to the VPN configuration file.
