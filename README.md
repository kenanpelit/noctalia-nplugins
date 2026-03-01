# Noctalia NPlugins

Custom Noctalia plugin registry maintained by Kenan Pelit.

## Repository Layout

- `registry.json`: index used by Noctalia custom plugin sources
- `ndns/`: DNS / VPN Switcher plugin
- `npodman/`: Podman dashboard plugin
- `notes/`: unified notes, scratchpad, and todos plugin
- `network/`: live network console plugin

## Runtime Dependencies

### ndns

`ndns` depends on external system commands to apply DNS and VPN changes:

- `osc-mullvad`: backend orchestrator for Mullvad / Blocky mode switching
- `mullvad`: Mullvad CLI
- `nmcli`: NetworkManager CLI
- `sudo -n` or `pkexec`: needed when stopping `blocky.service` during direct DNS preset changes

`ndns` first looks for `osc-mullvad` in `PATH`. If it is not found there, it also checks:

- `$HOME/.local/bin/osc-mullvad`

Reference implementation:

- `https://github.com/kenanpelit/cachyos/blob/main/modules/scripts/bin/osc-mullvad.sh`

### npodman

`npodman` depends on:

- `podman`

It uses the local Podman CLI directly from the user session.

## Add As A Noctalia Source

Use this repository URL in Noctalia plugin sources:

- `git@github.com:kenanpelit/noctalia-nplugins.git`
- or `https://github.com/kenanpelit/noctalia-nplugins`

Noctalia will fetch `registry.json`, then install the selected plugin subdirectory.
