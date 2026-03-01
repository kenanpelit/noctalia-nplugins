#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE="${HOME}/.local/state/ppd-auto-profile/lock"

json_bool() {
  if [[ "$1" == "1" ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

profile="unknown"
if command -v powerprofilesctl >/dev/null 2>&1; then
  profile="$(powerprofilesctl get 2>/dev/null || true)"
  [[ -n "$profile" ]] || profile="unknown"
fi

power_source="unknown"
battery_percent=-1
battery_status="unknown"
battery_available=0
for type_file in /sys/class/power_supply/*/type; do
  [[ -r "$type_file" ]] || continue
  type="$(cat "$type_file" 2>/dev/null || true)"
  base="${type_file%/type}"
  case "$type" in
    Mains)
      if [[ -r "$base/online" ]] && [[ "$(cat "$base/online" 2>/dev/null || echo 0)" == "1" ]]; then
        power_source="ac"
      fi
      ;;
    Battery)
      battery_available=1
      if [[ -r "$base/capacity" ]]; then
        battery_percent="$(cat "$base/capacity" 2>/dev/null || echo -1)"
      fi
      if [[ -r "$base/status" ]]; then
        battery_status="$(cat "$base/status" 2>/dev/null || echo unknown)"
      fi
      ;;
  esac
done
if [[ "$power_source" == "unknown" ]]; then
  if [[ "$battery_available" == "1" ]]; then
    power_source="battery"
  fi
fi

ppp_timer_active=0
if [[ "$(systemctl --user is-active ppp-auto-profile.timer 2>/dev/null || true)" == "active" ]]; then
  ppp_timer_active=1
fi

stasis_active=0
if [[ "$(systemctl --user is-active stasis.service 2>/dev/null || true)" == "active" ]]; then
  stasis_active=1
fi

auto_lock=0
[[ -f "$LOCK_FILE" ]] && auto_lock=1

idle_command_available=0
command -v qs >/dev/null 2>&1 && idle_command_available=1

printf '{\n'
printf '  "powerSource": "%s",\n' "$power_source"
printf '  "batteryAvailable": ' ; json_bool "$battery_available" ; printf ',\n'
printf '  "batteryPercent": %s,\n' "$battery_percent"
printf '  "batteryStatus": "%s",\n' "$battery_status"
printf '  "profile": "%s",\n' "$profile"
printf '  "pppTimerActive": ' ; json_bool "$ppp_timer_active" ; printf ',\n'
printf '  "autoProfileLocked": ' ; json_bool "$auto_lock" ; printf ',\n'
printf '  "stasisActive": ' ; json_bool "$stasis_active" ; printf ',\n'
printf '  "idleCommandAvailable": ' ; json_bool "$idle_command_available" ; printf '\n'
printf '}\n'
