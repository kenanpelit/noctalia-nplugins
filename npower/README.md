# NPower

Laptop-focused power management for Noctalia.

## Features

- Power source and battery snapshot
- Current `powerprofilesctl` profile visibility
- Direct profile switching (`power-saver`, `balanced`, `performance`)
- `ppp-auto-profile` lock/unlock control
- Session actions: lock, suspend, lock-and-suspend
- Noctalia idle inhibitor toggle

## Runtime Dependencies

- `powerprofilesctl`
- `systemctl`
- `loginctl`
- `qs` for idle inhibitor actions

## IPC

- `qs -c noctalia-shell ipc call plugin:npower togglePanel`
- `qs -c noctalia-shell ipc call plugin:npower cycleProfile`
- `qs -c noctalia-shell ipc call plugin:npower setProfile balanced`
- `qs -c noctalia-shell ipc call plugin:npower toggleLock`
- `qs -c noctalia-shell ipc call plugin:npower toggleIdleInhibit`
- `qs -c noctalia-shell ipc call plugin:npower lockAndSuspend`
