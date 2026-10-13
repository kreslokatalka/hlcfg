#!/usr/bin/env bash
set -u

VAULT="${OBSIDIAN_VAULT:-$HOME/documents/obsidian-master}"

if [[ -d "$VAULT/.git" ]]; then
    if ! git -C "$VAULT" pull --ff-only; then
        printf 'Obsidian vault update failed; starting Obsidian with the local copy.\n' >&2
    fi
else
    printf 'Obsidian vault repository not found at %s; skipping update.\n' "$VAULT" >&2
fi

exec obsidian "$@"