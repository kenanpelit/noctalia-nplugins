# Noctalia NPlugins

A curated third-party plugin registry for Noctalia, focused on practical workflows, polished UI, and deep system integration.

This repository is designed to be added as a custom Noctalia plugin source. Noctalia reads `registry.json`, then installs individual plugin directories from this repository.

## Included Plugins

| Plugin | ID | Purpose |
| --- | --- | --- |
| NDNS | `ndns` | DNS and VPN switching for Mullvad, Blocky, and direct DNS presets. |
| NCapture | `ncapture` | Unified screenshots, recording, and privacy-state capture workflow. |
| NPodman | `npodman` | Compact Podman dashboard for containers, images, and pods. |
| Notes Hub | `notes` | Unified scratchpad, note cards, and todo workflow. |
| Network Console | `network` | Live NetworkManager view with Wi-Fi visibility and quick actions. |
| NIP | `nip` | Compact public IP monitor with an icon-only bar presence. |

## Repository Structure

- `registry.json`: plugin index consumed by Noctalia custom sources
- `ndns/`: DNS and VPN control plugin
- `ncapture/`: capture workflow plugin
- `npodman/`: Podman management plugin
- `notes/`: productivity workspace plugin
- `network/`: network status and Wi-Fi control plugin
- `nip/`: public IP monitoring plugin

## Add This As A Noctalia Source

Add one of the following repository URLs in Noctalia plugin sources:

- `https://github.com/kenanpelit/noctalia-nplugins`
- `git@github.com:kenanpelit/noctalia-nplugins.git`

After adding the source, Noctalia will:

1. Fetch `registry.json`
2. List available plugins from this repository
3. Install the selected plugin subdirectory

## Runtime Requirements

Some plugins depend on external system tools. The main runtime requirements are:

### NCapture

`ncapture` is designed around the local capture stack:

- `gpu-screen-recorder`
- `grimblast` (or compatible screenshot command)
- PipeWire

The actual action commands are configurable in plugin settings so the plugin can adapt to existing workflows.

### NDNS

`ndns` uses external commands to manage DNS and VPN state:

- `osc-mullvad`
- `mullvad`
- `nmcli`
- `sudo -n` or `pkexec` when stopping `blocky.service` during direct DNS changes

`ndns` resolves `osc-mullvad` in this order:

1. `PATH`
2. `$HOME/.local/bin/osc-mullvad`

Reference implementation:

- `https://github.com/kenanpelit/cachyos/blob/main/modules/scripts/bin/osc-mullvad.sh`

### NPodman

`npodman` requires:

- `podman`

It interacts with the local user-session Podman CLI directly.

### Network Console

`network` requires:

- `nmcli`
- a running NetworkManager environment

### NIP

`nip` relies on the local networking stack and external connectivity to resolve public IP information.

## Planned Concepts

The repository also includes non-installable design blueprints under `concepts/` for future plugins:

- `ncapture`: unified capture, recording, and privacy workflow
- `npower`: laptop power, charging, and session power hub
- `nclipper`: notes + clipboard convergence roadmap
- `nkeyflow`: compositor and shell keybinding intelligence

These are intentionally kept out of `registry.json` until they are implemented.

## Compatibility

Plugins in this repository are maintained for modern Noctalia builds and use the minimum versions declared in `registry.json`.

## License

All plugins in this repository are published under the MIT license unless stated otherwise in the plugin metadata.
