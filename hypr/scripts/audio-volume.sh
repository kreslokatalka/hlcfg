#!/usr/bin/env bash
set -eu

readonly WPCTL=/usr/bin/wpctl
readonly SINK=@DEFAULT_AUDIO_SINK@

case "${1:-}" in
    mute)
        exec "$WPCTL" set-mute "$SINK" toggle
        ;;
    up)
        exec "$WPCTL" set-volume -l 1 "$SINK" 5%+
        ;;
    down)
        exec "$WPCTL" set-volume "$SINK" 5%-
        ;;
    *)
        printf 'Usage: %s {mute|up|down}\n' "$0" >&2
        exit 2
        ;;
esac