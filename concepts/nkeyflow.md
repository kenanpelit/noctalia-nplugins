# NKeyflow

Status: concept
Proposed plugin id: `nkeyflow`
Suggested name: `NKeyflow`

## Goal

Build a keybinding intelligence plugin that combines static compositor keybind visibility with live action routing for your shell-specific workflows.

## Why It Fits This System

This setup already has:

- Niri and Hyprland
- shell switching (`osc-shell`)
- plugin IPC heavy workflows
- custom launch scripts and routing logic

A plain cheatsheet is useful, but a routed, system-aware version would be better.

## Merge Sources

Primary inspiration:

- `keybind-cheatsheet`

Secondary system integration:

- `osc-shell`
- plugin IPC conventions already used in `noctalia-nplugins`

## Core UI

### Bar Widget

Minimal keyboard icon.

Left click:

- open panel

Right click:

- cycle view (global / compositor / shell plugins)

## Panel Layout

### Modes

- Global: user-facing shortcuts grouped by purpose
- Compositor: Niri / Hyprland parsed config bindings
- Shell: `osc-shell` and plugin IPC shortcuts
- Context: current backend-aware shortcuts (e.g. DMS vs Noctalia)

### Sections

- Applications
- Window Management
- Workspaces
- Media / Volume / Brightness
- Clipboard / Notes / DNS / Network / Podman
- Session / Lock / Power

## Smart Features

- auto-detect active compositor
- read Niri and Hyprland config files
- allow manual annotation for custom shell routes
- optionally surface “copy command” actions for shell IPC calls

## IPC Surface

Suggested commands:

- `plugin:nkeyflow togglePanel`
- `plugin:nkeyflow refresh`
- `plugin:nkeyflow setMode <global|compositor|shell|context>`
- `plugin:nkeyflow copyCommand <id>`

## Dependencies

- access to compositor config files
- optional `osc-shell` for active backend/context detection

## Implementation Notes

- Start as a read-only visibility tool
- Do not try to execute actions from the first version
- Prefer a structured parser over brittle regex-only rendering

## Phases

1. Parse Niri + Hyprland configs
2. Add manual custom command catalog for shell/plugin shortcuts
3. Add active backend/context filtering
4. Add copy-to-clipboard command helpers
