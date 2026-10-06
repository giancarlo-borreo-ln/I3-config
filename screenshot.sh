#!/bin/bash
# Screenshot utility.
#   region (default): select an area, save + copy to clipboard
#   full:             whole screen, save + copy to clipboard
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

mode="${1:-region}"

if [ "$mode" = "full" ]; then
    maim -u "$FILE"
else
    maim -s -u "$FILE"
fi

if [ -s "$FILE" ]; then
    xclip -selection clipboard -t image/png -i "$FILE" &
    notify-send -i "$FILE" "Screenshot" "Salvato e copiato: $(basename "$FILE")"
else
    rm -f "$FILE"
    notify-send "Screenshot" "Annullato (nessuna area selezionata)"
fi
