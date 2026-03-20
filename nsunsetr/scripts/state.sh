#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/sunsetr"
SCHEDULE_FILE="$CONFIG_ROOT/schedule.conf"
DEFAULT_CONFIG="$CONFIG_ROOT/sunsetr.toml"

declare -a schedule_starts=()
declare -a schedule_presets=()
declare -a schedule_temps=()
declare -a schedule_gammas=()

json_escape() {
  local s=${1-}
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/}
  s=${s//$'\t'/ }
  printf '%s' "$s"
}

json_bool() {
  if [[ "${1:-0}" == "1" ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

read_toml_value() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 0
  awk -v wanted="$key" '
    $0 ~ "^[[:space:]]*" wanted "[[:space:]]*=" {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      sub(/[[:space:]]*#.*/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^"|"$/, "", $0)
      print $0
      exit
    }
  ' "$file"
}

titleize() {
  printf '%s' "${1-}" | awk '{
    for (i = 1; i <= NF; ++i) {
      $i = toupper(substr($i, 1, 1)) substr($i, 2)
    }
    print
  }'
}

humanize_preset() {
  local preset="${1:-default}"
  if [[ "$preset" == "default" ]]; then
    printf 'Default\n'
  elif [[ "$preset" =~ ^([0-9]{2})([0-9]{2})-(.+)$ ]]; then
    printf '%s:%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$(titleize "${BASH_REMATCH[3]//-/ }")"
  else
    printf '%s\n' "$(titleize "${preset//-/ }")"
  fi
}

short_preset_label() {
  local preset="${1:-default}"
  if [[ "$preset" == "default" ]]; then
    printf 'Default\n'
  elif [[ "$preset" =~ ^([0-9]{2})([0-9]{2})-(.+)$ ]]; then
    printf '%s\n' "$(titleize "${BASH_REMATCH[3]//-/ }")"
  else
    printf '%s\n' "$(titleize "${preset//-/ }")"
  fi
}

resolve_preset_file() {
  local preset="${1:-default}"
  if [[ "$preset" == "default" ]]; then
    printf '%s\n' "$DEFAULT_CONFIG"
  else
    printf '%s/presets/%s/sunsetr.toml\n' "$CONFIG_ROOT" "$preset"
  fi
}

get_preset_temp() {
  local preset="${1:-default}"
  read_toml_value "$(resolve_preset_file "$preset")" static_temp
}

get_preset_gamma() {
  local preset="${1:-default}"
  read_toml_value "$(resolve_preset_file "$preset")" static_gamma
}

load_schedule() {
  local start preset temp gamma
  [[ -f "$SCHEDULE_FILE" ]] || return 0

  while read -r start preset; do
    [[ -n "$start" && -n "$preset" ]] || continue
    [[ "$start" =~ ^[0-9]{2}:[0-9]{2}$ ]] || continue
    [[ -f "$(resolve_preset_file "$preset")" ]] || continue
    temp="$(get_preset_temp "$preset")"
    gamma="$(get_preset_gamma "$preset")"
    schedule_starts+=("$start")
    schedule_presets+=("$preset")
    schedule_temps+=("${temp:-0}")
    schedule_gammas+=("${gamma:-0}")
  done < <(awk '
    /^[[:space:]]*#/ { next }
    NF >= 2 { print $1, $2 }
  ' "$SCHEDULE_FILE")
}

select_scheduled_preset() {
  local now_num="${1:-$(date +%H%M)}"
  local selected="default"
  local idx

  if [[ "${#schedule_presets[@]}" -eq 0 ]]; then
    printf 'default\n'
    return 0
  fi

  selected="${schedule_presets[$((${#schedule_presets[@]} - 1))]}"
  for idx in "${!schedule_starts[@]}"; do
    if [[ "${schedule_starts[$idx]//:/}" -le "$now_num" ]]; then
      selected="${schedule_presets[$idx]}"
    fi
  done
  printf '%s\n' "$selected"
}

next_schedule_index() {
  local now_num="${1:-$(date +%H%M)}"
  local idx

  if [[ "${#schedule_presets[@]}" -eq 0 ]]; then
    printf '0\n'
    return 0
  fi

  for idx in "${!schedule_starts[@]}"; do
    if [[ "${schedule_starts[$idx]//:/}" -gt "$now_num" ]]; then
      printf '%s\n' "$idx"
      return 0
    fi
  done
  printf '0\n'
}

service_active=0
timer_active=0
running=0
available=0
helper_available=0
config_available=0
schedule_available=0
error=""

if command -v sunsetr >/dev/null 2>&1; then
  available=1
fi

if command -v sunsetr-set >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/sunsetr-set" ]]; then
  helper_available=1
fi

[[ -f "$DEFAULT_CONFIG" ]] && config_available=1
[[ -f "$SCHEDULE_FILE" ]] && schedule_available=1

if systemctl --user is-active --quiet sunsetr.service 2>/dev/null; then
  service_active=1
  running=1
fi
if systemctl --user is-active --quiet sunsetr-auto-profile.timer 2>/dev/null; then
  timer_active=1
fi

load_schedule

active_preset="default"
if [[ "$available" -eq 1 ]]; then
  active_out="$(sunsetr preset active 2>/dev/null || true)"
  active_out="$(printf '%s' "$active_out" | tr -d '[:space:]')"
  [[ -n "$active_out" ]] && active_preset="$active_out"
fi

scheduled_preset="$(select_scheduled_preset)"
scheduled_label="$(humanize_preset "$scheduled_preset")"
active_label="$(humanize_preset "$active_preset")"
active_short_label="$(short_preset_label "$active_preset")"
manual_override=0
[[ "$active_preset" != "$scheduled_preset" ]] && manual_override=1

target_temp="$(get_preset_temp "$active_preset")"
target_gamma="$(get_preset_gamma "$active_preset")"
[[ -n "$target_temp" ]] || target_temp=0
[[ -n "$target_gamma" ]] || target_gamma=0
current_temp="$target_temp"
current_gamma="$target_gamma"
period="static"
state="stopped"
progress="0"

next_idx="$(next_schedule_index)"
if [[ "${#schedule_presets[@]}" -gt 0 ]]; then
  next_schedule_time="${schedule_starts[$next_idx]}"
  next_schedule_preset="${schedule_presets[$next_idx]}"
else
  next_schedule_time="--:--"
  next_schedule_preset="default"
fi

if [[ "$service_active" -eq 1 ]]; then
  state="steady"
fi

if [[ "$running" -eq 1 ]]; then
  status_json="$(sunsetr status --json 2>/dev/null || true)"
  if [[ -n "$status_json" ]] && command -v jq >/dev/null 2>&1; then
    parsed_period="$(printf '%s' "$status_json" | jq -r '.period // "static"' 2>/dev/null || true)"
    parsed_state="$(printf '%s' "$status_json" | jq -r '.state // "steady"' 2>/dev/null || true)"
    parsed_current_temp="$(printf '%s' "$status_json" | jq -r '.current_temp // empty' 2>/dev/null || true)"
    parsed_current_gamma="$(printf '%s' "$status_json" | jq -r '.current_gamma // empty' 2>/dev/null || true)"
    parsed_target_temp="$(printf '%s' "$status_json" | jq -r '.target_temp // empty' 2>/dev/null || true)"
    parsed_target_gamma="$(printf '%s' "$status_json" | jq -r '.target_gamma // empty' 2>/dev/null || true)"
    parsed_progress="$(printf '%s' "$status_json" | jq -r '.progress // 0' 2>/dev/null || true)"

    [[ -n "$parsed_period" ]] && period="$parsed_period"
    [[ -n "$parsed_state" ]] && state="$parsed_state"
    [[ -n "$parsed_current_temp" ]] && current_temp="$parsed_current_temp"
    [[ -n "$parsed_current_gamma" ]] && current_gamma="$parsed_current_gamma"
    [[ -n "$parsed_target_temp" ]] && target_temp="$parsed_target_temp"
    [[ -n "$parsed_target_gamma" ]] && target_gamma="$parsed_target_gamma"
    [[ -n "$parsed_progress" ]] && progress="$parsed_progress"
  elif [[ -z "$status_json" ]]; then
    error="sunsetr status returned no data"
  else
    error="jq is required for live sunsetr runtime parsing"
  fi
fi

schedule_json="["
if [[ "${#schedule_presets[@]}" -gt 0 ]]; then
  for idx in "${!schedule_presets[@]}"; do
    next=$(((idx + 1) % ${#schedule_presets[@]}))
    start="${schedule_starts[$idx]}"
    end="${schedule_starts[$next]}"
    preset="${schedule_presets[$idx]}"
    label="$(humanize_preset "$preset")"
    temp="${schedule_temps[$idx]}"
    gamma="${schedule_gammas[$idx]}"
    scheduled_flag=0
    active_flag=0
    [[ "$preset" == "$scheduled_preset" ]] && scheduled_flag=1
    [[ "$preset" == "$active_preset" ]] && active_flag=1
    [[ "$schedule_json" != "[" ]] && schedule_json+=","
    schedule_json+="{\"start\":\"$(json_escape "$start")\",\"end\":\"$(json_escape "$end")\",\"preset\":\"$(json_escape "$preset")\",\"label\":\"$(json_escape "$label")\",\"temp\":${temp:-0},\"gamma\":${gamma:-0},\"scheduled\":$(json_bool "$scheduled_flag"),\"active\":$(json_bool "$active_flag")}"
  done
fi
schedule_json+="]"

printf '{'
printf '"available":'; json_bool "$available"; printf ','
printf '"helperAvailable":'; json_bool "$helper_available"; printf ','
printf '"configAvailable":'; json_bool "$config_available"; printf ','
printf '"scheduleAvailable":'; json_bool "$schedule_available"; printf ','
printf '"serviceActive":'; json_bool "$service_active"; printf ','
printf '"timerActive":'; json_bool "$timer_active"; printf ','
printf '"running":'; json_bool "$running"; printf ','
printf '"activePreset":"%s",' "$(json_escape "$active_preset")"
printf '"activePresetLabel":"%s",' "$(json_escape "$active_label")"
printf '"activeShortLabel":"%s",' "$(json_escape "$active_short_label")"
printf '"scheduledPreset":"%s",' "$(json_escape "$scheduled_preset")"
printf '"scheduledPresetLabel":"%s",' "$(json_escape "$scheduled_label")"
printf '"nextScheduledPreset":"%s",' "$(json_escape "$next_schedule_preset")"
printf '"nextScheduledLabel":"%s",' "$(json_escape "$(short_preset_label "$next_schedule_preset")")"
printf '"nextScheduledTime":"%s",' "$(json_escape "$next_schedule_time")"
printf '"manualOverride":'; json_bool "$manual_override"; printf ','
printf '"period":"%s",' "$(json_escape "$period")"
printf '"state":"%s",' "$(json_escape "$state")"
printf '"currentTemp":%s,' "${current_temp:-0}"
printf '"currentGamma":%s,' "${current_gamma:-0}"
printf '"targetTemp":%s,' "${target_temp:-0}"
printf '"targetGamma":%s,' "${target_gamma:-0}"
printf '"progress":%s,' "${progress:-0}"
printf '"scheduleEntries":%s,' "$schedule_json"
printf '"error":"%s"' "$(json_escape "$error")"
printf '}\n'
