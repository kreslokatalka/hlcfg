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

## Install on Arch Linux

The installer supports Arch Linux and Arch-based distributions using `pacman`.
It installs the required packages from the configured repositories (no AUR helper
or third-party repository is used), copies the visual configs, and backs up any
files it replaces under `${XDG_STATE_HOME:-~/.local/state}/hlcfg/backups/`.

Review the installer before running it, then use:

```sh
curl -fsSL https://raw.githubusercontent.com/kreslokatalka/hlcfg/refs/heads/main/install.sh | bash
```

For a non-interactive install, add `--yes`:

```sh
curl -fsSL https://raw.githubusercontent.com/kreslokatalka/hlcfg/refs/heads/main/install.sh | bash -s -- --yes
```

Pass `--no-packages` if dependencies are already installed. The installer
preserves unrelated files in `~/.config` and rewrites this machine's hard-coded
home paths for the current user. Monitor names/modes in `hypr/modules/monitors.lua`
and the DDC/CI bus in the Waybar brightness scripts may need adjustment.