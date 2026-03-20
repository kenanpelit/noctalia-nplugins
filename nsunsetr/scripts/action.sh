#!/usr/bin/env bash
set -euo pipefail

resolve_helper() {
  if command -v sunsetr-set >/dev/null 2>&1; then
    command -v sunsetr-set
    return 0
  fi
  if [[ -x "$HOME/.local/bin/sunsetr-set" ]]; then
    printf '%s\n' "$HOME/.local/bin/sunsetr-set"
    return 0
  fi
  return 1
}

require_helper() {
  local helper
  helper="$(resolve_helper || true)"
  [[ -n "$helper" ]] || {
    echo "sunsetr-set is not available" >&2
    exit 1
  }
  printf '%s\n' "$helper"
}

ensure_running() {
  systemctl --user start sunsetr.service sunsetr-auto-profile.timer >/dev/null 2>&1 || true
  sleep 0.15
}

command -v sunsetr >/dev/null 2>&1 || {
  echo "sunsetr is not installed" >&2
  exit 1
}

cmd="${1:-}"
shift || true

case "$cmd" in
  auto)
    SUNSETR_SET="$(require_helper)"
    ensure_running
    "$SUNSETR_SET" auto --apply --no-notify >/dev/null
    echo "Auto preset applied"
    ;;
  default)
    SUNSETR_SET="$(require_helper)"
    ensure_running
    "$SUNSETR_SET" default --apply --no-notify >/dev/null
    echo "Default preset applied"
    ;;
  preset)
    preset="${1:-}"
    [[ -n "$preset" ]] || { echo "missing preset" >&2; exit 2; }
    SUNSETR_SET="$(require_helper)"
    ensure_running
    "$SUNSETR_SET" "$preset" --apply --no-notify >/dev/null
    echo "Preset -> $preset"
    ;;
  warmer)
    amount="${1:-150}"
    ensure_running
    sunsetr set "current_temp+=${amount}" >/dev/null
    echo "Warmer +${amount}K"
    ;;
  cooler)
    amount="${1:-150}"
    ensure_running
    sunsetr set "current_temp-=${amount}" >/dev/null
    echo "Cooler -${amount}K"
    ;;
  gamma-up)
    amount="${1:-2}"
    ensure_running
    sunsetr set "current_gamma+=${amount}" >/dev/null
    echo "Gamma +${amount}%"
    ;;
  gamma-down)
    amount="${1:-2}"
    ensure_running
    sunsetr set "current_gamma-=${amount}" >/dev/null
    echo "Gamma -${amount}%"
    ;;
  restart)
    systemctl --user restart sunsetr.service >/dev/null
    systemctl --user start sunsetr-auto-profile.timer >/dev/null
    echo "Sunsetr restarted"
    ;;
  *)
    echo "Usage: $0 {auto|default|preset <name>|warmer <k>|cooler <k>|gamma-up <pct>|gamma-down <pct>|restart}" >&2
    exit 2
    ;;
esac
