#!/usr/bin/env bash
set -euo pipefail
ROOT="/home/kreslo/.config/themes"
SOURCE="$ROOT/theme-gallery.c"
BINARY="$ROOT/theme-gallery"

if [[ ! -x "$BINARY" || "$SOURCE" -nt "$BINARY" ]]; then
    TEMP_BINARY="$ROOT/.theme-gallery.$$.new"
    trap 'rm -f "$TEMP_BINARY"' EXIT
    cc -std=c11 -O2 -Wall -Wextra "$SOURCE" -o "$TEMP_BINARY" $(pkg-config --cflags --libs gtk4)
    chmod 0755 "$TEMP_BINARY"
    mv "$TEMP_BINARY" "$BINARY"
    trap - EXIT
fi
# If this GTK application is already running, let its own activate handler
# toggle the existing window; it already owns the saved focus setting.
if pgrep -x theme-gallery >/dev/null 2>&1; then
    exec "$BINARY"
fi

exec "$BINARY"
