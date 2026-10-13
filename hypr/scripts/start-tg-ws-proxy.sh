#!/usr/bin/env bash
set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ENV_FILE="$CONFIG_HOME/tg-ws-proxy.env"

if [[ ! -r "$ENV_FILE" ]]; then
    printf 'Telegram WebSocket proxy credentials not found: %s\n' "$ENV_FILE" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"
if [[ -z "${TG_SECRET:-}" ]]; then
    printf 'TG_SECRET is not set in %s\n' "$ENV_FILE" >&2
    exit 1
fi

export TG_SECRET
exec tg-ws-proxy