# NSystem

Compact system console for Noctalia with live CPU, memory, disk, load, temperature, and top-process visibility.

## Features

- Live CPU usage in the bar
- Compact control center summary
- Panel with CPU, memory, disk, load, uptime, and temperature
- Top process snapshot
- Quick launch buttons for `btop`, `htop`, and `top`
- IPC actions for refresh and tool launch

## IPC

```bash
qs -c noctalia-shell ipc call plugin:nsystem togglePanel
qs -c noctalia-shell ipc call plugin:nsystem refresh
qs -c noctalia-shell ipc call plugin:nsystem openBtop
qs -c noctalia-shell ipc call plugin:nsystem openHtop
qs -c noctalia-shell ipc call plugin:nsystem openTop
```
