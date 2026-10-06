#!/bin/bash

# Turbo mode toggle script for Predator Tritton 300SE
# Save as ~/.config/i3/turbo_toggle.sh and make executable with: chmod +x ~/.config/i3/turbo_toggle.sh

STATE_FILE="/tmp/turbo_state"

# Try to find LED path (common Predator LED names)
for led in /sys/class/leds/phy0-led /sys/class/leds/predator* /sys/class/leds/*turbo*; do
    if [ -e "$led/brightness" ]; then
        LED_PATH="$led/brightness"
        break
    fi
done

# Check current state
if [ -f "$STATE_FILE" ]; then
    TURBO_ON=1
else
    TURBO_ON=0
fi

if [ $TURBO_ON -eq 0 ]; then
    # Enable turbo mode
    echo "Enabling turbo mode..."
    
    # CPU: Set performance governor
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    
    # GPU: Set max performance (NVIDIA - using nvidia-smi for better compatibility)
    if command -v nvidia-smi &> /dev/null; then
        # Lock GPU clocks to maximum
        sudo nvidia-smi -pm 1  # Enable persistence mode
        sudo nvidia-smi -lgc $(nvidia-smi --query-gpu=clocks.max.graphics --format=csv,noheader,nounits | head -1)
    elif command -v nvidia-settings &> /dev/null; then
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" > /dev/null 2>&1
    fi
    
    # Intel GPU: Set to maximum performance
    if [ -f /sys/class/drm/card0/gt_min_freq_mhz ]; then
        MAX_FREQ=$(cat /sys/class/drm/card0/gt_max_freq_mhz)
        echo "$MAX_FREQ" | sudo tee /sys/class/drm/card0/gt_min_freq_mhz > /dev/null
    fi
    
    # Note: Your system doesn't expose PWM fan controls
    # Fans are likely controlled automatically by firmware/BIOS
    # If you want manual control, you may need to install and configure nbfc-linux
    
    # LED: Turn on
    [ -f "$LED_PATH" ] && echo 1 | sudo tee "$LED_PATH"
    
    # Mark state
    touch "$STATE_FILE"
    
    # Send notification (if notification daemon is available)
    if command -v notify-send &> /dev/null && pgrep -x dunst > /dev/null 2>&1; then
        notify-send "Turbo Mode" "Enabled - Maximum Performance" -i dialog-information
    fi
    echo "✓ Turbo Mode ENABLED"
else
    # Disable turbo mode
    echo "Disabling turbo mode..."
    
    # CPU: Set powersave governor (or schedutil if available)
    if grep -q schedutil /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null; then
        echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    else
        echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    fi
    
    # GPU: Reset to auto performance (NVIDIA)
    if command -v nvidia-smi &> /dev/null; then
        # Reset GPU clocks to auto
        sudo nvidia-smi -pm 0  # Disable persistence mode
        sudo nvidia-smi -rgc
    elif command -v nvidia-settings &> /dev/null; then
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=0" > /dev/null 2>&1
    fi
    
    # Intel GPU: Reset to auto
    if [ -f /sys/class/drm/card0/gt_min_freq_mhz ]; then
        echo 0 | sudo tee /sys/class/drm/card0/gt_min_freq_mhz > /dev/null
    fi
    
    # Note: Fans return to automatic BIOS/firmware control
    # If you installed nbfc-linux, you can configure auto mode here
    
    # LED: Turn off
    [ -f "$LED_PATH" ] && echo 0 | sudo tee "$LED_PATH"
    
    # Clear state
    rm -f "$STATE_FILE"
    
    # Send notification (if notification daemon is available)
    if command -v notify-send &> /dev/null && pgrep -x dunst > /dev/null 2>&1; then
        notify-send "Turbo Mode" "Disabled - Balanced Performance" -i dialog-information
    fi
    echo "✓ Turbo Mode DISABLED"
fi
