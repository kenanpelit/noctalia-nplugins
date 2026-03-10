#!/usr/bin/env bash
set -euo pipefail

run_root() {
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    sudo -n ufw "$@"
    return $?
  fi
  if command -v pkexec >/dev/null 2>&1; then
    pkexec sh -c 'ufw "$@"' nufw-root "$@"
    return $?
  fi
  echo "Need sudo -n or pkexec to modify UFW" >&2
  return 1
}

is_enabled() {
  local out
  out="$(ufw status 2>/dev/null || true)"
  if [[ -z "${out:-}" ]] && command -v sudo >/dev/null 2>&1; then
    out="$(sudo -n ufw status 2>/dev/null || true)"
  fi
  grep -qi '^Status:[[:space:]]*active' <<<"$out"
}

cmd="${1:-}"
case "$cmd" in
  toggle)
    if is_enabled; then
      run_root disable >/dev/null
      echo "Firewall disabled"
    else
      run_root --force enable >/dev/null
      echo "Firewall enabled"
    fi
    ;;
  enable)
    run_root --force enable >/dev/null
    echo "Firewall enabled"
    ;;
  disable)
    run_root disable >/dev/null
    echo "Firewall disabled"
    ;;
  reload)
    run_root reload >/dev/null
    echo "Firewall reloaded"
    ;;
  *)
    echo "Usage: $0 {toggle|enable|disable|reload}" >&2
    exit 2
    ;;
esac
