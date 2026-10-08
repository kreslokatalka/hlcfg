#!/usr/bin/env bash
set -euo pipefail
theme=$(/home/kreslo/.config/themes/theme-manager.sh status)
if [[ "$theme" == dark ]]; then
    printf '{"text":"☾","tooltip":"Тема: тёмный лес · нажмите, чтобы выбрать"}\n'
else
    printf '{"text":"☼","tooltip":"Тема: светлая Rosewater · нажмите, чтобы выбрать"}\n'
fi