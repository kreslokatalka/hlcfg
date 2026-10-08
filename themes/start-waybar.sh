#!/usr/bin/env bash
set -euo pipefail

# The autostart event launches awww-daemon separately. Wait briefly for its IPC socket
# before restoring the selected wallpaper and starting a panel that uses that palette.
for _ in {1..30}; do
    if awww query >/dev/null 2>&1; then
        break
    fi
    sleep 0.2
done

/home/kreslo/.config/themes/theme-manager.sh restore
exec waybar