# NWorkspace

Monitor-aware workspace radar for Noctalia.

## What It Adds

- clearer workspace pills with better density than the built-in widget
- live window counts and quick preview markers
- panel view grouped by output
- direct window focus from the panel
- fast toggles for hiding empty workspaces and following the focused output

## Entry Points

- `Main.qml`
- `BarWidget.qml`
- `Panel.qml`
- `Settings.qml`

## Notes

- the plugin reads workspace and window state from `CompositorService`
- it is designed to work well with both Niri and Hyprland backends
- settings are global plugin settings, not per-bar-instance settings
