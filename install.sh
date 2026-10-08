#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="https://github.com/kreslokatalka/hlcfg"
ARCHIVE_URL="$REPOSITORY/archive/refs/heads/main.tar.gz"
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:?HOME must be set}/.config}"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/hlcfg/backups"

ASSUME_YES=0
INSTALL_PACKAGES=1
SOURCE_DIR=""

usage() {
    cat <<'EOF'
Install hlcfg's Hyprland desktop configuration on Arch Linux or an Arch-based system.

Usage:
  install.sh [--yes] [--no-packages] [--source-dir DIR]

Options:
  --yes             Do not ask for confirmation (required for unattended runs).
  --no-packages     Skip pacman; useful when dependencies are already installed.
  --source-dir DIR  Install from a local checkout instead of downloading GitHub.
  -h, --help        Show this help.

One-line installation:
  curl -fsSL https://raw.githubusercontent.com/kreslokatalka/hlcfg/main/install.sh | bash -s -- --yes
EOF
}

die() {
    printf 'hlcfg installer: error: %s\n' "$*" >&2
    exit 1
}

while (($#)); do
    case "$1" in
        --yes) ASSUME_YES=1; shift ;;
        --no-packages) INSTALL_PACKAGES=0; shift ;;
        --source-dir)
            (($# >= 2)) || die '--source-dir requires a directory'
            SOURCE_DIR=$2
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1 (use --help)" ;;
    esac
done

[[ $EUID -ne 0 ]] || die 'do not run as root; run as your desktop user'
command -v bash >/dev/null || die 'bash is required'
command -v tar >/dev/null || die 'tar is required'
command -v curl >/dev/null || [[ -n "$SOURCE_DIR" ]] || die 'curl is required to download the configuration'

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
else
    die 'cannot identify the operating system (/etc/os-release is missing)'
fi

if [[ "${ID:-}" != arch && " ${ID_LIKE:-} " != *' arch '* ]]; then
    die "unsupported distribution: ${PRETTY_NAME:-unknown}; this installer supports Arch Linux and Arch-based systems only"
fi

if ((INSTALL_PACKAGES)); then
    command -v pacman >/dev/null || die 'pacman is not available on this system'
    command -v sudo >/dev/null || die 'sudo is required to install packages'
fi

if ((!ASSUME_YES)); then
    [[ -r /dev/tty && -w /dev/tty ]] || die 'cannot prompt for confirmation; pass --yes to continue non-interactively'
    printf 'This will install packages (unless --no-packages is set) and deploy hlcfg to:\n  %s\n' "$CONFIG_HOME" >/dev/tty
    printf 'Existing files that would be replaced are backed up under:\n  %s\nContinue? [y/N] ' "$BACKUP_ROOT" >/dev/tty
    IFS= read -r answer </dev/tty || answer=''
    [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]] || { echo 'Cancelled.'; exit 0; }
fi

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/hlcfg-install.XXXXXX")
cleanup() { rm -rf -- "$WORK_DIR"; }
trap cleanup EXIT

if [[ -n "$SOURCE_DIR" ]]; then
    REPO_DIR=$(cd -- "$SOURCE_DIR" && pwd -P)
else
    ARCHIVE="$WORK_DIR/hlcfg.tar.gz"
    curl --fail --location --silent --show-error "$ARCHIVE_URL" --output "$ARCHIVE"
    tar -xzf "$ARCHIVE" -C "$WORK_DIR"
    REPO_DIR=$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d -name 'hlcfg-*' -print -quit)
    [[ -n "$REPO_DIR" ]] || die 'GitHub archive did not contain the expected repository directory'
fi

[[ -f "$REPO_DIR/README.md" && -f "$REPO_DIR/hypr/hyprland.lua" && -f "$REPO_DIR/themes/theme-manager.sh" ]] ||
    die 'source directory is not a complete hlcfg checkout'

if ((INSTALL_PACKAGES)); then
    PACKAGES=(
        awww base-devel dconf ddcutil fontconfig grim gtk-layer-shell gtk3 gtk4 gtk4-layer-shell
        dolphin gsettings-desktop-schemas hyprland hyprlock kitty libnotify noto-fonts noto-fonts-emoji
        pkgconf pipewire pipewire-pulse playerctl polkit-gnome python rofi slurp swaync
        ttf-hack-nerd waybar wireplumber wl-clipboard xdg-utils xdg-desktop-portal-hyprland
        xorg-xwayland
    )
    printf 'Installing required Arch packages: %s\n' "${PACKAGES[*]}"
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
fi

mkdir -p "$CONFIG_HOME"
STAMP=$(date '+%Y%m%d-%H%M%S')
BACKUP_DIR=""
BACKUP_CREATED=0

install_file() {
    local relative=$1 source="$REPO_DIR/$1" destination="$CONFIG_HOME/$1"
    [[ -f "$source" ]] || die "missing configuration file: $relative"
    mkdir -p "$(dirname -- "$destination")"
    if [[ -e "$destination" || -L "$destination" ]]; then
        if (( ! BACKUP_CREATED )); then
            mkdir -p "$BACKUP_ROOT"
            BACKUP_DIR=$(mktemp -d "$BACKUP_ROOT/$STAMP.XXXXXX")
            BACKUP_CREATED=1
        fi
        mkdir -p "$BACKUP_DIR/$(dirname -- "$relative")"
        cp -a -- "$destination" "$BACKUP_DIR/$relative"
        if [[ -L "$destination" ]]; then
            rm -- "$destination"
        fi
    fi
    install -m "$(stat -c '%a' "$source")" -- "$source" "$destination"
}

install_tree() {
    local relative=$1 source="$REPO_DIR/$1" file
    [[ -d "$source" ]] || die "missing configuration directory: $relative"
    while IFS= read -r -d '' file; do
        install_file "${file#"$REPO_DIR/"}"
    done < <(find "$source" -type f -print0)
}

# Copy only visual configuration and the scripts/resources it directly uses.
FILES=(
    fontconfig/fonts.conf
    gtk-3.0/gtk.css gtk-3.0/settings.ini
    gtk-4.0/gtk.css gtk-4.0/settings.ini
    hypr/hyprland.lua hypr/hyprlock.conf
    hypr/modules/autostart.lua hypr/modules/decorations.lua hypr/modules/environment.lua
    hypr/modules/keybinds.lua hypr/modules/monitors.lua hypr/modules/sectors.lua
    hypr/scripts/audio-volume.sh
    kitty/kitty.conf kitty/theme.conf kitty/theme-gallery-include.conf
    rofi/config.rasi rofi/themes/dark.rasi rofi/themes/light.rasi
    themes/open-gallery.sh themes/start-waybar.sh themes/theme-gallery.c
    themes/theme-manager.sh themes/theme-status.sh
    waybar/config.jsonc waybar/launch.sh waybar/style.css
    waybar/scripts/brightness.sh waybar/scripts/control-popover.c
    waybar/scripts/control-popover.sh waybar/scripts/volume.sh waybar/scripts/weather.sh
)

for relative in "${FILES[@]}"; do install_file "$relative"; done
install_tree hypr/images
install_tree themes/themes

# The checked-in configs originated on one host. Rewrite that host's paths in the
# installed text configs so the deployed files work for the current user/config dir.
python3 - "$CONFIG_HOME" "$HOME" "${FILES[@]}" <<'PY'
from pathlib import Path
import sys

config_home = sys.argv[1]
home = sys.argv[2]
paths = [Path(config_home) / name for name in sys.argv[3:]]
old_config = b"/home/kreslo/.config"
old_home = b"/home/kreslo"
for path in paths:
    if not path.is_file() or path.is_symlink():
        continue
    try:
        data = path.read_bytes()
    except OSError:
        continue
    if b"\0" not in data and (old_config in data or old_home in data):
        data = data.replace(old_config, config_home.encode())
        data = data.replace(old_home, home.encode())
        path.write_bytes(data)
PY

printf '\nConfiguration deployed to %s\n' "$CONFIG_HOME"
if ((BACKUP_CREATED)); then
    printf 'Replaced-file backups are in %s\n' "$BACKUP_DIR"
else
    printf 'No existing configuration files needed backup.\n'
fi
cat <<'EOF'

Next steps:
  1. Review hypr/modules/monitors.lua and set monitor names, modes and scale for this computer.
  2. Log into a Hyprland session. For audio controls, PipeWire/WirePlumber must be active.
  3. The brightness slider is configured for DDC/CI bus 2; edit waybar/scripts/control-popover.sh
     and waybar/scripts/brightness.sh if your monitor uses a different bus or does not support DDC/CI.
EOF