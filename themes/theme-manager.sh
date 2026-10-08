#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/kreslo/.config"
THEMES="$ROOT/themes/themes"
LIGHT_WALLPAPER="$ROOT/hypr/images/2.png"
FOREST_WALLPAPER="$THEMES/dark/wallpaper.jpg"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-theme-gallery"
STATE_FILE="$STATE_DIR/current"
THEME="${2:-${1:-}}"
ACTION="${1:-apply}"

case "$ACTION" in
    apply|restore|status) ;;
    *) echo "Usage: $0 {apply <light|dark>|restore|status}" >&2; exit 2 ;;
esac

if [[ "$ACTION" == "restore" ]]; then
    if [[ -r "$STATE_FILE" ]]; then
        IFS= read -r THEME < "$STATE_FILE" || true
    else
        THEME=light
    fi
fi

if [[ "$ACTION" == "status" ]]; then
    if [[ -r "$STATE_FILE" ]]; then IFS= read -r THEME < "$STATE_FILE" || true; else THEME=light; fi
    case "$THEME" in light|dark) printf '%s\n' "$THEME" ;; *) printf '%s\n' light ;; esac
    exit 0
fi

case "$THEME" in light|dark) ;; *) echo "Unknown theme: $THEME (expected light or dark)" >&2; exit 2 ;; esac
DIR="$THEMES/$THEME"
for file in waybar.css kitty.conf gtk-3.0-settings.ini gtk-3.0.css gtk-4.0-settings.ini gtk-4.0.css; do
    [[ -r "$DIR/$file" ]] || { echo "Missing theme asset: $DIR/$file" >&2; exit 1; }
done
if [[ "$THEME" == dark && ! -r "$FOREST_WALLPAPER" ]]; then
    echo "Missing dark theme wallpaper: $FOREST_WALLPAPER" >&2
    exit 1
fi

mkdir -p "$STATE_DIR"
TEMP_DIR=$(mktemp -d "$STATE_DIR/.apply.XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT

cp "$DIR/waybar.css" "$TEMP_DIR/waybar.css"
cp "$DIR/kitty.conf" "$TEMP_DIR/kitty-theme.conf"
cp "$DIR/gtk-3.0-settings.ini" "$TEMP_DIR/gtk-3.0-settings.ini"
cp "$DIR/gtk-3.0.css" "$TEMP_DIR/gtk-3.0.css"
cp "$DIR/gtk-4.0-settings.ini" "$TEMP_DIR/gtk-4.0-settings.ini"
cp "$DIR/gtk-4.0.css" "$TEMP_DIR/gtk-4.0.css"
printf '%s\n' "$THEME" > "$TEMP_DIR/current"
printf '\n# Theme gallery palette (managed by ~/.config/themes/theme-manager.sh)\ninclude /home/kreslo/.config/kitty/theme.conf\n' > "$TEMP_DIR/kitty-include.conf"

# Stage all assets before touching live configuration files.
install -m 0644 "$TEMP_DIR/waybar.css" "$ROOT/waybar/.style.css.theme-new"
install -m 0644 "$TEMP_DIR/kitty-theme.conf" "$ROOT/kitty/.theme.conf.theme-new"
install -m 0644 "$TEMP_DIR/gtk-3.0-settings.ini" "$ROOT/gtk-3.0/.settings.ini.theme-new"
install -m 0644 "$TEMP_DIR/gtk-3.0.css" "$ROOT/gtk-3.0/.gtk.css.theme-new"
install -m 0644 "$TEMP_DIR/gtk-4.0-settings.ini" "$ROOT/gtk-4.0/.settings.ini.theme-new"
install -m 0644 "$TEMP_DIR/gtk-4.0.css" "$ROOT/gtk-4.0/.gtk.css.theme-new"
install -m 0644 "$TEMP_DIR/kitty-include.conf" "$ROOT/kitty/.kitty-theme-include.conf.theme-new"

mv "$ROOT/waybar/.style.css.theme-new" "$ROOT/waybar/style.css"
mv "$ROOT/kitty/.theme.conf.theme-new" "$ROOT/kitty/theme.conf"
mv "$ROOT/gtk-3.0/.settings.ini.theme-new" "$ROOT/gtk-3.0/settings.ini"
mv "$ROOT/gtk-3.0/.gtk.css.theme-new" "$ROOT/gtk-3.0/gtk.css"
mv "$ROOT/gtk-4.0/.settings.ini.theme-new" "$ROOT/gtk-4.0/settings.ini"
mv "$ROOT/gtk-4.0/.gtk.css.theme-new" "$ROOT/gtk-4.0/gtk.css"
mv "$ROOT/kitty/.kitty-theme-include.conf.theme-new" "$ROOT/kitty/theme-gallery-include.conf"
mv "$TEMP_DIR/current" "$STATE_FILE"

# Use per-user GTK preferences and files; do not override the environment of every app.
if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas | grep -qx org.gnome.desktop.interface; then
    if [[ "$THEME" == dark ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
    fi
fi

# Keep Hyprland's inherited GTK theme in sync for applications opened after switching.
if [[ "$THEME" == dark ]]; then
    hyprctl eval 'hl.env("GTK_THEME", "Adwaita:dark")' >/dev/null 2>&1 || true
    hyprctl eval 'hl.config({general = {col = {active_border = {colors = {"rgba(75C99Aff)", "rgba(315F49ff)"}, angle = 45}, inactive_border = "rgba(354C3Fff)"}}})' >/dev/null 2>&1 || true
    ROFI_THEME='themes/dark.rasi'
    THEME_LABEL='Dark forest'
else
    hyprctl eval 'hl.env("GTK_THEME", "Adwaita")' >/dev/null 2>&1 || true
    hyprctl eval 'hl.config({general = {col = {active_border = {colors = {"rgba(55CDFCff)", "rgba(F7A8B8ff)"}, angle = 45}, inactive_border = "rgba(B9C9D9ff)"}}})' >/dev/null 2>&1 || true
    ROFI_THEME='themes/light.rasi'
    THEME_LABEL='Rosewater'
fi

# Keep wallpaper changes isolated from the GTK event loop; awww may need time to
# decode and upload a full-resolution image. Bilinear keeps that work lightweight.
if command -v awww >/dev/null 2>&1; then
    if [[ "$THEME" == dark ]]; then
        WALLPAPER="$FOREST_WALLPAPER"
    else
        WALLPAPER="$LIGHT_WALLPAPER"
    fi
    if [[ -r "$WALLPAPER" ]]; then
        nohup awww img "$WALLPAPER" --resize crop --filter Bilinear --transition-type none \
            >/dev/null 2>&1 </dev/null &
    fi
fi

cat > "$TEMP_DIR/rofi-config.rasi" <<EOF
configuration {
    modi: "drun,run,window";
    show-icons: true;
    drun-display-format: "{name}";
    font: "Noto Sans 11";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
}
@theme "$ROFI_THEME"
EOF
install -m 0644 "$TEMP_DIR/rofi-config.rasi" "$ROOT/rofi/.config.rasi.theme-new"
if [[ "$THEME" == dark ]]; then
    install -m 0644 "$DIR/rofi.rasi" "$ROOT/rofi/themes/.dark.rasi.theme-new"
    mv "$ROOT/rofi/themes/.dark.rasi.theme-new" "$ROOT/rofi/themes/dark.rasi"
fi
mv "$ROOT/rofi/.config.rasi.theme-new" "$ROOT/rofi/config.rasi"

# Kitty reads the palette through include on fresh terminals. Existing terminals can
# reload their configuration safely if remote control is enabled.
if pgrep -x kitty >/dev/null 2>&1; then
    kitty @ set-colors --all --configured "$ROOT/kitty/theme.conf" >/dev/null 2>&1 || true
fi

# Waybar has no reliable CSS-only reload in this setup. Restart it out of band after
# the theme files are committed; the gallery never waits for this UI process.
if [[ "$ACTION" == apply && "${THEME_MANAGER_SKIP_RESTART:-0}" != 1 ]] && pgrep -x waybar >/dev/null 2>&1; then
    nohup bash -c 'pkill -x waybar 2>/dev/null || true; sleep 0.25; exec /home/kreslo/.config/themes/start-waybar.sh' \
        >/dev/null 2>&1 </dev/null &
fi

if [[ "$ACTION" == apply && "${2:-}" != "--quiet" ]] && [[ "${THEME_MANAGER_QUIET:-0}" != 1 ]] && command -v notify-send >/dev/null 2>&1; then
    nohup notify-send -a "Theme gallery" -i preferences-desktop-theme "$THEME_LABEL" "Desktop palette applied" -t 2600 \
        >/dev/null 2>&1 </dev/null &
fi
