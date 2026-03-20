# NSunsetr

![nsunsetr preview](preview.png)

Sunsetr schedule, preset, and live temperature controls for Noctalia.

## Highlights

- compact bar widget with period icon and live Kelvin or preset label
- detailed panel for active preset, current target, next schedule boundary, and quick actions
- one-click access to scheduled presets from `~/.config/sunsetr/schedule.conf`
- warmer/cooler and gamma adjustments through native `sunsetr set current_*` commands
- integrates with the `sunsetr` + `sunsetr-set` flow used in the Cachy Niri session

## Runtime Requirements

- `sunsetr`
- `sunsetr-set`
- `systemctl --user`
- `jq`

The plugin expects a repo-managed Sunsetr setup with:

- `~/.config/sunsetr/sunsetr.toml`
- `~/.config/sunsetr/schedule.conf`
- `~/.config/sunsetr/presets/*`

## IPC

```bash
qs -c noctalia-shell ipc call plugin:nsunsetr toggle
qs -c noctalia-shell ipc call plugin:nsunsetr auto
qs -c noctalia-shell ipc call plugin:nsunsetr warmer
qs -c noctalia-shell ipc call plugin:nsunsetr cooler
qs -c noctalia-shell ipc call plugin:nsunsetr gammaUp
qs -c noctalia-shell ipc call plugin:nsunsetr gammaDown
qs -c noctalia-shell ipc call plugin:nsunsetr setPreset 2100-dusk
```
