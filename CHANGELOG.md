# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - Unreleased

### Added

- Option `-c` to connect to a specific Wireguar configuration
- Option `-d` to disconnect to a specific Wireguar configuration
- Option `-l` to list all Wireguard configuration
- Option `-s` to show the status of Wireguard
- Autocomplation for bash
- Installer script
- `.wgbconf.json` configuration file
- 2FA management
- `path` commands to `add`, `delete` and `list` paths in the configuration file
- Handler for configuration file during installation and upgrade
- Options `connect`, `disconnect`, `list` and `status` to commands
- 2FA manager that allow to manage it on a connection-by-connection basis
- Logging errors in the default Linux log directory
