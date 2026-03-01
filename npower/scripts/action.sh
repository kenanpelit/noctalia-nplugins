#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE="${HOME}/.local/state/ppd-auto-profile/lock"
cmd="${1:-}"
shift || true

current_profile() {
  powerprofilesctl get 2>/dev/null || true
}

lock_via_shell() {
  qs -c noctalia-shell ipc call lockScreen lock \
    || qs -c noctalia-shell ipc call sessionMenu lock
}

case "$cmd" in
  set-profile)
    mode="${1:-}"
    [[ -n "$mode" ]] || { echo "missing profile" >&2; exit 1; }
    powerprofilesctl set "$mode"
    ;;
  cycle-profile)
    current="$(current_profile)"
    case "$current" in
      power-saver) next="balanced" ;;
      balanced) next="performance" ;;
      performance) next="power-saver" ;;
      *) next="balanced" ;;
    esac
    powerprofilesctl set "$next"
    printf '%s\n' "$next"
    ;;
  toggle-lock)
    mkdir -p "$(dirname "$LOCK_FILE")"
    if [[ -f "$LOCK_FILE" ]]; then
      rm -f "$LOCK_FILE"
      printf 'unlocked\n'
    else
      : > "$LOCK_FILE"
      printf 'locked\n'
    fi
    ;;
  lock)
    lock_via_shell || loginctl lock-session || loginctl lock-sessions
    ;;
  suspend)
    systemctl suspend
    ;;
  lock-and-suspend)
    qs -c noctalia-shell ipc call sessionMenu lockAndSuspend \
      || { lock_via_shell || true; sleep 1; systemctl suspend; }
    ;;
  idle-toggle)
    qs -c noctalia-shell ipc call idleInhibitor toggle
    ;;
  idle-enable)
    qs -c noctalia-shell ipc call idleInhibitor enable
    ;;
  idle-disable)
    qs -c noctalia-shell ipc call idleInhibitor disable
    ;;
  *)
    echo "unknown action: $cmd" >&2
    exit 1
    ;;
esac
