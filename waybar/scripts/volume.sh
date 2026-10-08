#!/usr/bin/env bash
set -eu

read -r volume muted < <(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '
    { printf "%d %d\n", ($2 * 100 + 0.5), ($3 == "[MUTED]") }
') || true
volume=${volume:-0}
muted=${muted:-0}

if [[ "$muted" == 1 ]]; then
    text="◖×"
    class="muted"
    tooltip="Muted · left click: volume slider · right click: toggle mute"
else
    icon="◖))"
    text="$icon"
    class=""
    tooltip="Volume ${volume}% · left click: volume slider · right click: toggle mute"
fi

python3 -c 'import json,sys; print(json.dumps({"text":sys.argv[1],"class":sys.argv[2],"tooltip":sys.argv[3]},ensure_ascii=False))' \
    "$text" "$class" "$tooltip"