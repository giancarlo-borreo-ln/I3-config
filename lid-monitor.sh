#!/bin/bash
# Automatic display layout for an Optimus laptop (Intel iGPU + NVIDIA dGPU) on X11.
#
#   * External monitor connected -> it becomes the ONLY active display, driven
#     at its preferred resolution and the highest refresh rate it supports.
#   * No external monitor -> the internal laptop panel is used.
#
# This script is also used by LightDM (display-setup-script) so the login screen
# appears on the external monitor too. It must therefore stay root-safe and
# must not depend on the caller's environment.

set -u

LAPTOP_DISPLAY="eDP-1"

# --- 1. Expose the NVIDIA GPU outputs on the Intel "modesetting" screen --------
# On this laptop the HDMI/DP connector is physically wired to the NVIDIA GPU.
# X11 uses the Intel modesetting driver as the primary screen, so the NVIDIA
# provider's outputs must be slaved to it before they can be enabled. Without
# this the output is detected as "connected" but never lights up.
PROVIDERS=$(xrandr --listproviders 2>/dev/null)
if echo "$PROVIDERS" | grep -q "name:NVIDIA"; then
    NVIDIA_ID=$(echo "$PROVIDERS" | awk '/name:NVIDIA/ {print $2}' | tr -d ':')
    MODESET_ID=$(echo "$PROVIDERS" | awk '/name:modesetting/ {print $2}' | tr -d ':')
    if [ -n "$NVIDIA_ID" ] && [ -n "$MODESET_ID" ]; then
        xrandr --setprovideroutputsource "$NVIDIA_ID" "$MODESET_ID"
    fi
fi

# --- 2. Find a connected external display -------------------------------------
EXTERNAL=$(xrandr --query | awk '/ connected/ {print $1}' \
    | grep -v "^${LAPTOP_DISPLAY}$" | head -n 1)

# --- 3. Apply the layout -------------------------------------------------------
if [ -n "$EXTERNAL" ]; then
    # Preferred mode line for the external output (the one marked with '+').
    PREF_LINE=$(xrandr --query | awk -v out="$EXTERNAL" '
        $1==out {inside=1; next}
        inside && /^[^[:space:]]/ {exit}
        inside && /\+/ {print; exit}')
    PREF_MODE=$(echo "$PREF_LINE" | awk '{print $1}')
    # Highest refresh rate advertised for that mode.
    BEST_RATE=$(echo "$PREF_LINE" \
        | awk '{for(i=2;i<=NF;i++){gsub(/[*+]/,"",$i); if($i ~ /^[0-9]+\.[0-9]+$/) print $i}}' \
        | sort -g | tail -n 1)

    if [ -n "$PREF_MODE" ] && [ -n "$BEST_RATE" ]; then
        xrandr --output "$EXTERNAL" --mode "$PREF_MODE" --rate "$BEST_RATE" --primary
    else
        xrandr --output "$EXTERNAL" --primary --auto
    fi
    xrandr --output "$LAPTOP_DISPLAY" --off
else
    xrandr --output "$LAPTOP_DISPLAY" --auto --primary
fi
