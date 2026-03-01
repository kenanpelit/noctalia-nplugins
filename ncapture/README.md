# NCapture

Unified capture workflow plugin for Noctalia.

`NCapture` combines three practical concerns into one place:

- screenshot actions
- screen recording control
- live privacy visibility (microphone, camera, and screen sharing state)

## Scope

This first version focuses on:

- configurable screenshot actions
- configurable `gpu-screen-recorder` start/stop commands
- lightweight live recording detection
- PipeWire-backed microphone and screen-share visibility
- camera activity detection via local device access checks

## Included UI

- **Bar Widget**: compact capture state icon, right click toggles recording
- **Panel**: screenshot actions, recording controls, and privacy state cards
- **Control Center Widget**: quick entry point into the panel
- **Settings**: command and polling configuration

## Suggested Dependencies

- `gpu-screen-recorder`
- `grimblast` (or your preferred screenshot command)
- PipeWire
- an operational Wayland / portal setup

## IPC Commands

```bash
qs -c noctalia-shell ipc call plugin:ncapture togglePanel
qs -c noctalia-shell ipc call plugin:ncapture toggle
qs -c noctalia-shell ipc call plugin:ncapture start
qs -c noctalia-shell ipc call plugin:ncapture stop
qs -c noctalia-shell ipc call plugin:ncapture refresh
qs -c noctalia-shell ipc call plugin:ncapture screenshotRegion
qs -c noctalia-shell ipc call plugin:ncapture screenshotScreen
qs -c noctalia-shell ipc call plugin:ncapture screenshotWindow
```

## Notes

The plugin intentionally uses shell-command settings for the actual screenshot and recording actions. That keeps the first version practical for systems that already have their own preferred capture tooling.
