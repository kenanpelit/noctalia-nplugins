#!/usr/bin/env bash
set -euo pipefail

curl_json() {
  local url="$1"
  curl -fsS --connect-timeout 3 --max-time 8 -H 'Accept: application/json' "$url"
}

json_escape() {
  printf '%s' "${1:-}" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

print_mullvad_cli_fallback() {
  local status_output="$1"
  local relay visible location ip country city relay_name relay_kind protocol

  relay="$(printf '%s\n' "$status_output" | awk -F'Relay:[[:space:]]*' '/Relay:/ {print $2; exit}' | xargs || true)"
  visible="$(printf '%s\n' "$status_output" | awk -F'Visible location:[[:space:]]*' '/Visible location:/ {print $2; exit}' | xargs || true)"
  ip="$(printf '%s\n' "$visible" | sed -n 's/.*IPv4:[[:space:]]*\([0-9.]\{7,\}\).*/\1/p' | head -n 1)"
  location="${visible%%. IPv4:*}"

  country="${location%%,*}"
  city=""
  if [[ "$location" == *,* ]]; then
    city="${location#*, }"
  fi

  relay_name="${relay%% *}"
  relay_kind="$(printf '%s' "$relay_name" | awk -F- '{print toupper($3)}')"
  case "$relay_kind" in
    WG) protocol="WireGuard" ;;
    OVPN) protocol="OpenVPN" ;;
    *) protocol="$relay_kind" ;;
  esac

  [[ -n "$ip" ]] || return 1

  printf '{'
  printf '"ip":"%s",' "$(json_escape "$ip")"
  printf '"country":"%s",' "$(json_escape "$country")"
  printf '"city":"%s",' "$(json_escape "$city")"
  printf '"mullvad_exit_ip":true,'
  printf '"mullvad_exit_ip_hostname":"%s",' "$(json_escape "$relay_name")"
  printf '"mullvad_server_type":"%s",' "$(json_escape "$protocol")"
  printf '"organization":"Mullvad"'
  printf '}\n'
}

mullvad_status=""
if command -v mullvad >/dev/null 2>&1; then
  mullvad_status="$(mullvad status -v 2>/dev/null || true)"
fi

if printf '%s' "$mullvad_status" | grep -q '^Connected'; then
  payload="$(curl_json "https://am.i.mullvad.net/json" 2>/dev/null || true)"
  if [[ -n "$payload" ]]; then
    printf '%s\n' "$payload"
    exit 0
  fi

  if payload="$(print_mullvad_cli_fallback "$mullvad_status" 2>/dev/null)"; then
    printf '%s\n' "$payload"
    exit 0
  fi
fi

for url in \
  "https://ipwho.is/" \
  "https://ipapi.co/json/" \
  "https://ifconfig.co/json" \
  "https://ipinfo.io/json"
do
  payload="$(curl_json "$url" 2>/dev/null || true)"
  if [[ -n "$payload" ]]; then
    printf '%s\n' "$payload"
    exit 0
  fi
done

echo "Failed to fetch public IP details from all providers" >&2
exit 1
