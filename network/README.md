# Network Console

A richer NetworkManager-powered network plugin for Noctalia.

## Features

- live connection state via `nmcli monitor`
- polished bar widget with connection status
- detailed panel with current path, IP, gateway, and nearby Wi-Fi list
- quick Wi-Fi actions: refresh, radio toggle, rescan
- low-frequency watchdog fallback instead of aggressive polling

## IPC

```bash
qs -c noctalia-shell ipc call plugin:network togglePanel
qs -c noctalia-shell ipc call plugin:network refresh
qs -c noctalia-shell ipc call plugin:network wifiToggle
qs -c noctalia-shell ipc call plugin:network wifiEnable
qs -c noctalia-shell ipc call plugin:network wifiDisable
qs -c noctalia-shell ipc call plugin:network wifiRescan
```
