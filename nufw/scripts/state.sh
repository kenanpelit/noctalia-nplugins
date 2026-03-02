#!/usr/bin/env bash
set -euo pipefail

json_escape() {
  local s=${1-}
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/}
  s=${s//$'\t'/ }
  printf '%s' "$s"
}

run_read() {
  local out
  if command -v sudo >/dev/null 2>&1; then
    if out="$(sudo -n ufw "$@" 2>/dev/null)"; then
      printf '%s\n' "$out"
      return 0
    fi
  fi
  if out="$(ufw "$@" 2>/dev/null)"; then
    printf '%s\n' "$out"
    return 0
  fi
  return 1
}

if ! command -v ufw >/dev/null 2>&1; then
  printf '{"available":false,"readable":false,"status":"unavailable","loggingLevel":"n/a","incomingPolicy":"n/a","outgoingPolicy":"n/a","routedPolicy":"n/a","ruleCount":0,"rulesPreview":"","error":"ufw command not found"}\n'
  exit 0
fi

status_text="$(run_read status verbose || true)"
numbered_text="$(run_read status numbered || true)"

if [[ -z "$status_text" ]]; then
  printf '{"available":true,"readable":false,"status":"unknown","loggingLevel":"n/a","incomingPolicy":"n/a","outgoingPolicy":"n/a","routedPolicy":"n/a","ruleCount":0,"rulesPreview":"","error":"Unable to read UFW status without privileges"}\n'
  exit 0
fi

status="$(printf '%s\n' "$status_text" | awk -F': ' '/^Status:/{print tolower($2); exit}')"
logging="$(printf '%s\n' "$status_text" | awk -F': ' '/^Logging:/{print $2; exit}')"
default_line="$(printf '%s\n' "$status_text" | sed -n 's/^Default: //p' | head -n1)"
incoming="$(printf '%s' "$default_line" | sed -n 's/^\([^,]*\) (incoming).*/\1/p')"
outgoing="$(printf '%s' "$default_line" | sed -n 's/.*,[[:space:]]*\([^,]*\) (outgoing).*/\1/p')"
routed="$(printf '%s' "$default_line" | sed -n 's/.*,[[:space:]]*\([^,]*\) (routed).*/\1/p')"
[[ -n "$status" ]] || status="unknown"
[[ -n "$logging" ]] || logging="n/a"
[[ -n "$incoming" ]] || incoming="n/a"
[[ -n "$outgoing" ]] || outgoing="n/a"
[[ -n "$routed" ]] || routed="n/a"
rule_count="$(printf '%s\n' "$numbered_text" | awk '/^\[[[:space:]]*[0-9]+\]/{c++} END{print c+0}')"
rules_preview="$(printf '%s\n' "$numbered_text" | awk '/^\[[[:space:]]*[0-9]+\]/{sub(/^\[[^]]+\][[:space:]]*/, "", $0); print}' | head -n 5)"

printf '{"available":true,"readable":true,"status":"%s","loggingLevel":"%s","incomingPolicy":"%s","outgoingPolicy":"%s","routedPolicy":"%s","ruleCount":%s,"rulesPreview":"%s","error":""}\n' \
  "$(json_escape "$status")" \
  "$(json_escape "$logging")" \
  "$(json_escape "$incoming")" \
  "$(json_escape "$outgoing")" \
  "$(json_escape "$routed")" \
  "$rule_count" \
  "$(json_escape "$rules_preview")"
