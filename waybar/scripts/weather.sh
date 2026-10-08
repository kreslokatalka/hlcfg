#!/usr/bin/env bash
set -eu

python3 - <<'PY'
import json
import urllib.request

url = (
    "https://api.open-meteo.com/v1/forecast"
    "?latitude=56.3269&longitude=44.0059"
    "&current=temperature_2m,apparent_temperature,weather_code"
    "&timezone=Europe%2FMoscow&language=en"
)
try:
    request = urllib.request.Request(url, headers={"User-Agent": "Waybar-NizhnyNovgorod/1.0"})
    with urllib.request.urlopen(request, timeout=8) as response:
        current = json.load(response)["current"]
    code = current["weather_code"]
    conditions = (
        "Clear" if code == 0 else
        "Partly cloudy" if code in (1, 2) else
        "Cloudy" if code == 3 else
        "Fog" if code in (45, 48) else
        "Drizzle" if code in (51, 53, 55, 56, 57) else
        "Rain" if code in (61, 63, 65, 66, 67, 80, 81, 82) else
        "Snow" if code in (71, 73, 75, 77, 85, 86) else
        "Thunderstorm" if code in (95, 96, 99) else
        "Weather"
    )
    text = f"Nizhny Novgorod {current['temperature_2m']:+g}°C"
    tooltip = (
        f"Nizhny Novgorod: {current['temperature_2m']:+g}°C, {conditions}\n"
        f"Feels like {current['apparent_temperature']:+g}°C · Open-Meteo"
    )
except Exception:
    text = "Nizhny Novgorod --°C"
    tooltip = "Weather temporarily unavailable · Open-Meteo"

print(json.dumps({"text": text, "tooltip": tooltip}, ensure_ascii=False))
PY