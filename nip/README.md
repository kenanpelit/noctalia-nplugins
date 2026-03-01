# NIP

![nip preview](preview.png)

A compact public IP monitor for Noctalia, based on the original `ip-monitor` plugin and adapted for this custom registry.

## Highlights

- icon-only bar widget
- left click opens a detailed IP panel
- right click offers copy, refresh, and settings actions
- automatic background refresh using `curl`

## IPC

```bash
qs -c noctalia-shell ipc call plugin:nip refreshIp
qs -c noctalia-shell ipc call plugin:nip toggle
```

## Requirements

- `curl`
- `wl-copy` if you want the copy action from the context menu
