# Desktop visual configuration

This local repository tracks the visual configuration used by this Hyprland
desktop: Hyprland appearance and related scripts, Waybar, GTK, Kitty, Rofi,
Fontconfig, the theme gallery/manager and the wallpapers those configs use.

## Included

- `hypr/` — compositor appearance, lock screen, bindings, startup and wallpapers.
- `waybar/` — panel layout, CSS and supporting scripts/source.
- `themes/` — light/dark palettes, rotated dark wallpaper and theme switcher.
- `gtk-3.0/`, `gtk-4.0/`, `kitty/`, `rofi/`, `fontconfig/` — application styling.

Compiled helper binaries, runtime theme state, old backups, browser/application
profiles, caches and credentials are intentionally not tracked.

The current scripts contain this machine's `/home/kreslo/.config` paths, so
using the configs under another account requires adapting those paths.