#!/bin/bash
# Screen locker used by xss-lock (idle + suspend).
# The AUR "i3lock-color" package installs its binary as /usr/bin/i3lock,
# so we detect colour support at runtime and fall back to plain i3lock.

IMG=/home/giancarlo/Pictures/Wallpapers/moraine-lake.jpg

if pacman -Qo /usr/bin/i3lock 2>/dev/null | grep -q i3lock-color || i3lock --version 2>&1 | grep -q '\.c\.'; then
    i3lock -n -i "$IMG" --blur 5 --clock --indicator \
        --insidever-color=2e3440cc --ringver-color=88c0d0ff \
        --insidewrong-color=2e3440cc --ringwrong-color=bf616aff \
        --inside-color=2e3440cc --ring-color=88c0d0ff \
        --line-color=00000000 --separator-color=00000000 \
        --verif-color=ffffff --wrong-color=ffffff \
        --time-color=ffffff --date-color=ffffff \
        --keyhl-color=a3be8cff --bshl-color=bf616aff
else
    i3lock -n -i "$IMG"
fi
