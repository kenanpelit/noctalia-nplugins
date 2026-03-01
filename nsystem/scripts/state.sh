#!/usr/bin/env bash
set -euo pipefail

read -r _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ < /proc/stat
sleep 0.15
read -r _ u2 n2 s2 i2 w2 irq2 sirq2 st2 _ < /proc/stat

total1=$((u1+n1+s1+i1+w1+irq1+sirq1+st1))
total2=$((u2+n2+s2+i2+w2+irq2+sirq2+st2))
idlev1=$((i1+w1))
idlev2=$((i2+w2))
delta_total=$((total2-total1))
delta_idle=$((idlev2-idlev1))
if [ "$delta_total" -le 0 ]; then
  cpu_percent=0
else
  cpu_percent=$(((100*(delta_total-delta_idle))/delta_total))
fi

mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
mem_used_kb=$((mem_total_kb-mem_avail_kb))
if [ "$mem_total_kb" -le 0 ]; then
  mem_percent=0
else
  mem_percent=$((100*mem_used_kb/mem_total_kb))
fi
mem_used_gib=$(awk -v n="$mem_used_kb" 'BEGIN { printf "%.1f", n/1048576 }')
mem_total_gib=$(awk -v n="$mem_total_kb" 'BEGIN { printf "%.1f", n/1048576 }')

read -r disk_size disk_used disk_pcent <<EOF2
$(df -B1 --output=size,used,pcent / | awk 'NR==2 {gsub(/%/, "", $3); print $1, $2, $3}')
EOF2
: "${disk_size:=0}"
: "${disk_used:=0}"
: "${disk_pcent:=0}"
disk_used_gib=$(awk -v n="$disk_used" 'BEGIN { printf "%.1f", n/1073741824 }')
disk_total_gib=$(awk -v n="$disk_size" 'BEGIN { printf "%.1f", n/1073741824 }')

load1=$(awk '{print $1}' /proc/loadavg)
uptime_seconds=$(cut -d. -f1 /proc/uptime)
if [ "$uptime_seconds" -lt 60 ]; then
  uptime_human="${uptime_seconds}s"
elif [ "$uptime_seconds" -lt 3600 ]; then
  uptime_human="$((uptime_seconds/60))m"
elif [ "$uptime_seconds" -lt 86400 ]; then
  uptime_human="$((uptime_seconds/3600))h"
else
  uptime_human="$((uptime_seconds/86400))d"
fi

temp_raw=""
for zone in /sys/class/thermal/thermal_zone*/temp; do
  [ -r "$zone" ] || continue
  temp_raw=$(cat "$zone" 2>/dev/null || true)
  if [ -n "$temp_raw" ]; then
    break
  fi
done
if [ -n "$temp_raw" ]; then
  temp_c=$(awk -v n="$temp_raw" 'BEGIN { if (n > 1000) printf "%.1f", n/1000; else printf "%.1f", n }')
else
  temp_c=""
fi

top_line=$(ps -eo comm=,%cpu= --sort=-%cpu | awk 'NR==1 {print $1 "|" $2}')
if [ -n "$top_line" ]; then
  top_name=${top_line%%|*}
  top_cpu=${top_line#*|}
else
  top_name="idle"
  top_cpu="0.0"
fi

jq -n \
  --argjson cpuUsage "$cpu_percent" \
  --argjson memPercent "$mem_percent" \
  --arg memUsedGiB "$mem_used_gib" \
  --arg memTotalGiB "$mem_total_gib" \
  --argjson diskPercent "$disk_pcent" \
  --arg diskUsedGiB "$disk_used_gib" \
  --arg diskTotalGiB "$disk_total_gib" \
  --arg load1 "$load1" \
  --arg uptime "$uptime_human" \
  --arg tempC "$temp_c" \
  --arg topProcessName "$top_name" \
  --arg topProcessCpu "$top_cpu" \
  '{
    cpuUsage: $cpuUsage,
    memPercent: $memPercent,
    memUsedGiB: ($memUsedGiB | tonumber),
    memTotalGiB: ($memTotalGiB | tonumber),
    diskPercent: $diskPercent,
    diskUsedGiB: ($diskUsedGiB | tonumber),
    diskTotalGiB: ($diskTotalGiB | tonumber),
    load1: ($load1 | tonumber),
    uptime: $uptime,
    tempC: (if $tempC == "" then null else ($tempC | tonumber) end),
    topProcessName: $topProcessName,
    topProcessCpu: ($topProcessCpu | tonumber)
  }'
