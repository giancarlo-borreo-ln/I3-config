#!/bin/bash
# Re-apply the display layout whenever a monitor is plugged or unplugged.
# Runs inside the i3 session (as the user), so xrandr works without root.

SCRIPT="$HOME/.config/i3/lid-monitor.sh"
last=""

while true; do
    cur=$(xrandr --query 2>/dev/null | awk '/ connected/ {print $1}' | sort | tr '\n' ',')
    if [ "$cur" != "$last" ]; then
        "$SCRIPT"
        last="$cur"
    fi
    sleep 2
done
