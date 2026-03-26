# NIP

![nip preview](preview.png)

A compact public IP monitor for Noctalia, based on the original `ip-monitor` plugin and adapted for this custom registry.

## Highlights

- icon-only bar widget
- left click opens a detailed IP panel
- right click offers copy, refresh, and settings actions
- automatic background refresh with Mullvad-aware provider fallback

## IPC

```bash
qs -c noctalia-shell ipc call plugin:nip refreshIp
qs -c noctalia-shell ipc call plugin:nip toggle
```

## Requirements

- `curl`
- `mullvad` for direct Mullvad-aware detection when the VPN is connected
- `wl-copy` if you want the copy action from the context menu
