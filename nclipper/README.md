# NClipper

Focused clipboard capture for Noctalia.

## Features

- Reads the current text clipboard
- Save reusable snippets locally
- Pin important snippets to keep them at the top
- Recopy saved items back into the clipboard
- Lightweight bar and control-center presence

## Runtime Dependencies

- `wl-paste`
- `wl-copy`

## IPC

- `qs -c noctalia-shell ipc call plugin:nclipper togglePanel`
- `qs -c noctalia-shell ipc call plugin:nclipper refresh`
- `qs -c noctalia-shell ipc call plugin:nclipper saveCurrent`
- `qs -c noctalia-shell ipc call plugin:nclipper pinCurrent`
