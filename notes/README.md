# Notes Hub

![notes preview](preview.png)

A unified Noctalia productivity plugin that merges three workflows into one panel:

- scratchpad capture for fast, disposable text
- durable note cards for reference material
- actionable todos with priority cycling

## Included entry points

- `main`
- `barWidget`
- `controlCenterWidget`
- `panel`
- `settings`

## IPC

```bash
qs -c noctalia-shell ipc call plugin:notes togglePanel
qs -c noctalia-shell ipc call plugin:notes addTodo "Ship the patch" high
qs -c noctalia-shell ipc call plugin:notes addNote "Meeting" "Decision log"
qs -c noctalia-shell ipc call plugin:notes quickCapture "Temporary thought"
qs -c noctalia-shell ipc call plugin:notes setScratchpad "Current scratchpad text"
```
