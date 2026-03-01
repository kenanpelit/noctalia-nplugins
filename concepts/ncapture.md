# NCapture

Status: concept
Proposed plugin id: `ncapture`
Suggested name: `NCapture`

## Goal

Unify screenshot, screen recording, and privacy-state visibility into a single capture workflow plugin.

## Why It Fits This System

The current desktop already uses:

- Wayland
- PipeWire
- `gpu-screen-recorder`
- screenshot tooling (`grim`, `slurp`, `satty`, compositor-native helpers)
- portal-based screen sharing and recording

The result is that capture state already exists in multiple places, but it is fragmented. `ncapture` would make this operationally coherent.

## Merge Sources

Primary inspiration and merge targets:

- `screen-recorder`
- `privacy-indicator`
- `screenshot`

## Core UI

### Bar Widget

A compact capture-status capsule:

- idle: neutral icon
- screenshot ready: neutral
- recording active: strong red accent
- screen share active: amber/purple warning state
- microphone active during recording: secondary dot or split accent

Left click:

- opens panel

Right click:

- quick toggle record / stop

## Panel Layout

### Header

- current mode: idle / recording / sharing / mixed
- destination folder
- last capture summary

### Primary Actions

- Screenshot Region
- Screenshot Monitor
- Screenshot Window
- Start Recording
- Stop Recording
- Copy Last Capture
- Open Output Folder

### Recording Section

- source: portal / screen / monitor / region
- codec
- fps
- audio source
- cursor toggle
- clipboard-after-save toggle

### Privacy Section

Live status cards:

- microphone
- camera
- screen share

Each card should display:

- active/inactive state
- detected app(s) where available

## IPC Surface

Suggested commands:

- `plugin:ncapture togglePanel`
- `plugin:ncapture screenshot region`
- `plugin:ncapture screenshot monitor`
- `plugin:ncapture screenshot window`
- `plugin:ncapture record start`
- `plugin:ncapture record stop`
- `plugin:ncapture record toggle`
- `plugin:ncapture openOutput`
- `plugin:ncapture copyLast`

## Dependencies

- `gpu-screen-recorder`
- compositor screenshot stack (`grim`, `slurp`, `satty` or compositor-specific helpers)
- `xdg-desktop-portal`
- PipeWire

## Implementation Notes

- Prefer event-driven state where possible
- Reuse the privacy detection approach from `privacy-indicator`
- Keep screenshot and recording backends replaceable
- Avoid separate plugins fighting over the same bar surface

## Phases

1. Implement bar + panel shell
2. Wire screenshots only
3. Add recording state machine
4. Add privacy monitoring
5. Add last-capture history and clipboard actions
