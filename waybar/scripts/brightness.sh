#!/usr/bin/env bash
set -eu

brightness=$(timeout 5 ddcutil --bus 2 getvcp 10 2>/dev/null | sed -nE 's/.*current value = *([0-9]+),.*/\1/p' | head -1 || true)
if [[ "$brightness" =~ ^[0-9]+$ ]]; then
    python3 -c 'import json,sys; value=sys.argv[1]; print(json.dumps({"text":"☼","tooltip":f"Brightness {value}% · Samsung U28E590 · click for slider"},ensure_ascii=False))' "$brightness"
else
    printf '%s\n' '{"text":"☼","tooltip":"Brightness unavailable · Samsung U28E590 DDC/CI"}'
fi