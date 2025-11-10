#!/bin/bash
# monitor.sh - Linux System Monitor
# Usage: ./monitor.sh [--alert] [--save <file>]

ALERT=false
SAVE_FILE=""
THRESHOLD_CPU=85
THRESHOLD_MEM=85
THRESHOLD_DISK=90

# parse args
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --alert) ALERT=true; shift ;;
    --save) SAVE_FILE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
UPTIME_INFO=$(uptime -p)

# CPU usage
CPU_IDLE=$(top -bn1 | grep "%Cpu(s)" | awk -F'id,' '{ split($1,parts,","); print parts[length(parts)] }' | awk '{print $NF}')
CPU_USAGE=$(awk "BEGIN {printf \"%.0f\", 100 - $CPU_IDLE}")

# Memory usage
MEM_FREE_KB=$(grep MemFree /proc/meminfo | awk '{print $2}')
MEM_TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_USED_KB=$((MEM_TOTAL_KB - MEM_FREE_KB))
MEM_USAGE=$(awk "BEGIN {printf \"%.0f\", ($MEM_USED_KB/$MEM_TOTAL_KB)*100}")

# Disk usage for root /
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

# Top processes
TOP_CPU=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6)
TOP_MEM=$(ps -eo pid,comm,%mem --sort=-%mem | head -n 6)

# Network stats
NET_STATS=$(cat /proc/net/dev | sed '1,2d' | awk '{gsub(":"," "); if ($1!="lo") printf "%s rx:%s tx:%s\\n", $1, $2, $10}')

REPORT="Timestamp: $TIMESTAMP
Host: $HOSTNAME
Uptime: $UPTIME_INFO

CPU Usage: ${CPU_USAGE}%
Memory Usage: ${MEM_USAGE}%
Disk Usage (/): ${DISK_USAGE}%

Top CPU processes:
$TOP_CPU

Top Memory processes:
$TOP_MEM

Network stats:
$NET_STATS
"

# print report
echo -e "$REPORT"

# save if requested
if [[ -n "$SAVE_FILE" ]]; then
  echo -e "$REPORT" >> "$SAVE_FILE"
  echo "Saved report to $SAVE_FILE"
fi

# alert check
if $ALERT; then
  ALERT_MSG=""
  if (( CPU_USAGE >= THRESHOLD_CPU )); then
    ALERT_MSG+="CPU usage high: ${CPU_USAGE}%\n"
  fi
  if (( MEM_USAGE >= THRESHOLD_MEM )); then
    ALERT_MSG+="Memory usage high: ${MEM_USAGE}%\n"
  fi
  if (( DISK_USAGE >= THRESHOLD_DISK )); then
    ALERT_MSG+="Disk usage high: ${DISK_USAGE}%\n"
  fi

  if [[ -n "$ALERT_MSG" ]]; then
    if [[ -x "./alerts.sh" ]]; then
      ./alerts.sh "$ALERT_MSG"
    else
      echo -e "ALERT:\n$ALERT_MSG"
    fi
  fi
fi
