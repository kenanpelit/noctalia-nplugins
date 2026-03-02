# NUFW

Lightweight UFW firewall controls for Noctalia with a compact bar widget, quick actions, and a readable status panel.

## Features

- Active / inactive firewall state
- Default incoming / outgoing policy visibility
- Logging and routed policy visibility
- Quick actions for enable, disable, reload, and refresh
- Rule preview from `ufw status numbered`

## Notes

- State reads try `sudo -n` first, then plain `ufw`.
- Mutating actions require `sudo -n` or `pkexec`.
- If neither is available, actions will fail with a visible error message.
