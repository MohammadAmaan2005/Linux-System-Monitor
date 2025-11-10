#!/bin/bash
# alerts.sh - helper script to send alerts
# Usage: ./alerts.sh "message"

MSG="$1"

# Desktop notification
if command -v notify-send >/dev/null 2>&1; then
  notify-send "System Monitor Alert" "$MSG"
fi

# Email alert (if mail configured)
if command -v mail >/dev/null 2>&1; then
  echo -e "$MSG" | mail -s "System Monitor Alert" you@example.com
fi

# Fallback
echo -e "ALERT SENT:\n$MSG"
