#!/usr/bin/env bash
set -eu

kind=${1:?Usage: control-popover.sh volume|brightness}
pid_file="/tmp/waybar-control-popover-${kind}.pid"

# Toggle: a second click on the same tray icon closes the open slider.
if [[ -f "$pid_file" ]]; then
    pkill -x control-popover 2>/dev/null || true
    rm -f "$pid_file"
    exit 0
fi

case "$kind" in
    volume)
        initial=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%d", $2 * 100 + 0.5}') || initial=50
        ;;
    brightness)
        initial=$(timeout 5 ddcutil --bus 2 getvcp 10 2>/dev/null | sed -nE 's/.*current value = *([0-9]+),.*/\1/p' | head -1 || true)
        initial=${initial:-50}
        ;;
    *) echo "Unknown slider: $kind" >&2; exit 2 ;;
esac

# Use the cursor only to determine which monitor contains the clicked Waybar.
# Position the slider using that monitor's Waybar layer geometry and the fixed
# icon widths, so the cursor's exact click point never affects the anchor.
cursor=$(hyprctl cursorpos 2>/dev/null | tr -d ' ')
cursor_x=${cursor%%,*}
cursor_y=${cursor#*,}
[[ "$cursor_x" =~ ^-?[0-9]+$ && "$cursor_y" =~ ^-?[0-9]+$ ]] || exit 1

monitor=$(hyprctl monitors -j | python3 -c '
import json,sys
x,y=map(int,sys.argv[1:3])
monitors=json.load(sys.stdin)
for m in monitors:
    scale=m.get("scale",1) or 1
    width=int(m["width"]/scale)
    height=int(m["height"]/scale)
    if m["x"] <= x < m["x"]+width and m["y"] <= y < m["y"]+height:
        print(m["name"], m["x"], m["y"], width, height, scale)
        break
' "$cursor_x" "$cursor_y")
[[ -n "$monitor" ]] || exit 1
read -r monitor_name monitor_x monitor_y monitor_width monitor_height monitor_scale <<<"$monitor"

layer=$(hyprctl layers -j | python3 -c '
import json,sys
name=sys.argv[1]
data=json.load(sys.stdin)
for item in data.get(name,{}).get("levels",{}).values():
    for layer in item:
        if layer.get("namespace")=="waybar":
            print(layer["x"],layer["y"],layer["w"],layer["h"])
            raise SystemExit
' "$monitor_name")
[[ -n "$layer" ]] || exit 1
read -r bar_x bar_y bar_width bar_height <<<"$layer"

# Include the bar's 1px right border and 7px right padding, plus each module's
# 28px minimum width, 1px borders and 3px side margins. Order: volume, brightness.
outer_border=1
right_padding=7
button_width=30
button_margin=3
if [[ "$kind" == "volume" ]]; then
    button_x=$((bar_x + bar_width - outer_border - right_padding - button_margin - button_width / 2 - button_margin * 2 - button_width - 2))
else
    button_x=$((bar_x + bar_width - outer_border - right_padding - button_margin - button_width / 2))
fi
anchor_y=$((bar_y + bar_height))

binary="/home/kreslo/.config/waybar/scripts/control-popover"
source_file="${binary}.c"
if [[ ! -x "$binary" || "$source_file" -nt "$binary" ]]; then
    cc -O2 -Wall -Wextra "$source_file" -o "$binary" $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0)
fi

pkill -x control-popover 2>/dev/null || true
rm -f /tmp/waybar-control-popover-*.pid
nohup "$binary" "$kind" "$button_x" "$anchor_y" "$initial" >/dev/null 2>&1 </dev/null &