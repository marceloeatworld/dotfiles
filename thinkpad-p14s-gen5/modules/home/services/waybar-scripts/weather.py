#!/usr/bin/env python3
"""
Multi-city weather monitor for Waybar using Open-Meteo API
Displays current weather for Lagos (PT), Paris (FR), Bejaia (DZ), and Kaunas (LT).
Optimized: Concurrent requests using ThreadPoolExecutor
"""

import json
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

# Configuration
CACHE_FILE = Path.home() / ".cache" / "weather-waybar.json"
CACHE_DURATION = timedelta(minutes=10)
API_BASE = "https://api.open-meteo.com/v1/forecast"
TIMEOUT = 10

# Cities configuration: (name, country_code, latitude, longitude, emoji_flag)
CITIES = [
    ("Lagos", "PT", 37.1017, -8.6731, "🇵🇹"),
    ("Paris", "FR", 48.8566, 2.3522, "🇫🇷"),
    ("Bejaia", "DZ", 36.7525, 5.0856, "🇩🇿"),
    ("Kaunas", "LT", 54.8985, 23.9036, "🇱🇹"),
]

# Weather code mapping (WMO Weather interpretation codes)
WEATHER_CODES = {
    0: ("Clear sky", "☀️"),
    1: ("Mainly clear", "🌤️"),
    2: ("Partly cloudy", "⛅"),
    3: ("Overcast", "☁️"),
    45: ("Foggy", "🌫️"),
    48: ("Depositing rime fog", "🌫️"),
    51: ("Light drizzle", "🌦️"),
    53: ("Moderate drizzle", "🌦️"),
    55: ("Dense drizzle", "🌧️"),
    56: ("Light freezing drizzle", "🌧️"),
    57: ("Dense freezing drizzle", "🌧️"),
    61: ("Slight rain", "🌧️"),
    63: ("Moderate rain", "🌧️"),
    65: ("Heavy rain", "🌧️"),
    66: ("Light freezing rain", "🌧️"),
    67: ("Heavy freezing rain", "🌧️"),
    71: ("Slight snow", "🌨️"),
    73: ("Moderate snow", "❄️"),
    75: ("Heavy snow", "❄️"),
    77: ("Snow grains", "❄️"),
    80: ("Slight rain showers", "🌦️"),
    81: ("Moderate rain showers", "🌧️"),
    82: ("Violent rain showers", "⛈️"),
    85: ("Slight snow showers", "🌨️"),
    86: ("Heavy snow showers", "❄️"),
    95: ("Thunderstorm", "⛈️"),
    96: ("Thunderstorm with hail", "⛈️"),
    99: ("Thunderstorm with heavy hail", "⛈️"),
}


def load_theme_colors():
    """Load runtime theme colors from Nix-generated files."""
    colors = {"FG": "#d4d4d4", "DIM": "#9d9d9d", "ACCENT": "#d4c080",
              "RED": "#d08080", "GREEN": "#90c090", "BLUE": "#90a8c8",
              "ORANGE": "#c8a080", "CYAN": "#80b8c8"}
    theme_files = [
        Path.home() / ".config/waybar/scripts/theme-colors.sh",
        Path.home() / ".config/theme/current/colors.sh",
    ]
    for theme_file in theme_files:
        if not theme_file.exists():
            continue
        for line in theme_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, v = line.split('=', 1)
                k = k.strip().replace('C_', '')
                colors[k] = v.strip().strip('"')
    return colors

C = load_theme_colors()

def h(text):
    return f"<span color='{C['ACCENT']}'><b>{text}</b></span>"

def v(text):
    return f"<span color='{C['FG']}'>{text}</span>"

def d(text):
    return f"<span color='{C['DIM']}'>{text}</span>"


def get_weather_icon(weather_code):
    """Get weather icon and description from WMO code"""
    return WEATHER_CODES.get(weather_code, ("Unknown", "❓"))


def fetch_weather(city_data):
    """Fetch weather data from Open-Meteo API for a single city"""
    city_name, country_code, lat, lon, flag = city_data

    params = {
        "latitude": lat,
        "longitude": lon,
        "current_weather": "true",
        "hourly": "temperature_2m,relativehumidity_2m,precipitation,windspeed_10m",
        "timezone": "auto",
    }

    url = f"{API_BASE}?{'&'.join(f'{k}={v}' for k, v in params.items())}"

    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "Waybar-Weather/1.0"}
        )
        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            data = json.loads(response.read().decode())

        current = data.get("current_weather", {})
        hourly = data.get("hourly", {})

        current_time = datetime.fromisoformat(current.get("time", datetime.now().isoformat()))
        hour_index = current_time.hour

        return {
            "city": city_name,
            "country_code": country_code,
            "flag": flag,
            "temperature": current.get("temperature", 0),
            "windspeed": current.get("windspeed", 0),
            "weather_code": current.get("weathercode", 0),
            "time": current.get("time", ""),
            "humidity": hourly.get("relativehumidity_2m", [0]*24)[hour_index] if hourly else 0,
            "precipitation": hourly.get("precipitation", [0]*24)[hour_index] if hourly else 0,
        }

    except Exception as e:
        print(f"API Error for {city_name}: {e}", file=sys.stderr)
        return None


def get_cached_data():
    """Get cached weather data if still valid"""
    if not CACHE_FILE.exists():
        return None

    try:
        with open(CACHE_FILE, 'r') as f:
            data = json.load(f)

        cached_time = datetime.fromisoformat(data['timestamp'])
        if datetime.now() - cached_time < CACHE_DURATION:
            return data['weather']
    except (json.JSONDecodeError, KeyError, ValueError):
        pass

    return None


def save_cache(weather_data):
    """Save weather data to cache"""
    CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(CACHE_FILE, 'w') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'weather': weather_data
        }, f)


def fetch_all_weather():
    """Fetch weather for all cities concurrently"""
    cached = get_cached_data()
    if cached:
        return cached

    weather_data = []

    # Use ThreadPoolExecutor for concurrent requests
    with ThreadPoolExecutor(max_workers=len(CITIES)) as executor:
        futures = {executor.submit(fetch_weather, city): city for city in CITIES}

        for future in as_completed(futures):
            result = future.result()
            if result:
                weather_data.append(result)

    # Sort by original city order
    city_order = {city[0]: i for i, city in enumerate(CITIES)}
    weather_data.sort(key=lambda w: city_order.get(w['city'], 999))

    if weather_data:
        save_cache(weather_data)

    return weather_data


def get_world_clocks():
    """Get current times for different timezones"""
    timezones = [
        ("🇺🇸", "New York", "America/New_York"),
        ("🇺🇸", "Las Vegas", "America/Los_Angeles"),
        ("🇨🇳", "Beijing", "Asia/Shanghai"),
        ("🇱🇹", "Vilnius", "Europe/Vilnius"),
    ]

    clocks = []
    for flag, name, tz in timezones:
        try:
            clocks.append((flag, name, datetime.now(ZoneInfo(tz)).strftime("%H:%M")))
        except Exception:
            continue

    return clocks


def create_tooltip(weather_data):
    """Create Pango markup tooltip with all cities weather"""
    if not weather_data:
        return "Failed to fetch weather data\nRetrying in 10 minutes..."

    lines = [h("󰖐  WEATHER"), ""]

    for weather in weather_data:
        desc, icon = get_weather_icon(weather["weather_code"])
        city = weather["city"]
        flag = weather["flag"]
        temp = weather["temperature"]
        wind = weather["windspeed"]
        humidity = weather["humidity"]
        precip = weather["precipitation"]

        # Color temperature based on value
        if temp >= 30:
            temp_color = C['RED']
        elif temp >= 20:
            temp_color = C['ORANGE']
        elif temp >= 10:
            temp_color = C['FG']
        elif temp >= 0:
            temp_color = C['CYAN']
        else:
            temp_color = C['BLUE']

        lines.append(f"{flag}  {v(f'{city.upper():<7}')} {icon} {d(desc)}")
        lines.append(f"    <span color='{temp_color}'><b>{temp:>3.0f}°C</b></span>  {d(f'{wind:>2.0f}km/h')}  {d(f'{humidity:>3.0f}%')}" +
                     (f"  {d(f'{precip:.1f}mm')}" if precip > 0 else ""))

    # World Clocks section
    lines.append("")
    lines.append(h("󰥔  CLOCKS"))
    lines.append("")
    for flag, name, time_str in get_world_clocks():
        lines.append(f"{flag}  {d(f'{name:<10}')} <span color='{C['FG']}'><b>{time_str}</b></span>")

    return "\n".join(lines)


def main():
    """Main entry point"""
    weather_data = fetch_all_weather()

    if not weather_data:
        output = {
            "text": "🌡️ N/A",
            "tooltip": "Failed to fetch weather data\nRetrying in 10 minutes...",
            "class": "weather-error"
        }
    else:
        first = weather_data[0]
        _, icon = get_weather_icon(first["weather_code"])
        temp = first["temperature"]

        output = {
            "text": f"{icon} {temp:.0f}°C",
            "tooltip": create_tooltip(weather_data),
            "class": "weather"
        }

    print(json.dumps(output))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        error_output = {
            "text": "🌡️ ERR",
            "tooltip": f"Weather Error:\n{str(e)}",
            "class": "weather-error"
        }
        print(json.dumps(error_output))
        sys.exit(1)
