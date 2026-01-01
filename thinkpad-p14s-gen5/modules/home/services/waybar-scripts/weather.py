#!/usr/bin/env python3
"""
Multi-city weather monitor for Waybar using Open-Meteo API
Displays current weather for Lagos (PT), Paris (FR), Bejaia (DZ), Kaunas (LT)
"""

import json
import sys
import urllib.request
import urllib.error
from datetime import datetime, timedelta
from pathlib import Path

# Configuration
CACHE_FILE = Path.home() / ".cache" / "weather-waybar.json"
CACHE_DURATION = timedelta(minutes=10)  # Cache for 10 minutes
API_BASE = "https://api.open-meteo.com/v1/forecast"
TIMEOUT = 10  # seconds

# Cities configuration: (name, country_code, latitude, longitude, emoji_flag)
CITIES = [
    ("Lagos", "PT", 37.1017, -8.6731, "🇵🇹"),
    ("Paris", "FR", 48.8566, 2.3522, "🇫🇷"),
    ("Bejaia", "DZ", 36.7525, 5.0856, "🇩🇿"),
    ("Kaunas", "LT", 54.8985, 23.9036, "🇱🇹"),
    ("Nicosia", "CY", 35.1856, 33.3823, "🇨🇾"),
    ("San José", "CR", 9.9281, -84.0907, "🇨🇷"),
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


def get_weather_icon(weather_code):
    """Get weather icon and description from WMO code"""
    return WEATHER_CODES.get(weather_code, ("Unknown", "❓"))


def fetch_weather(city_name, lat, lon):
    """Fetch weather data from Open-Meteo API"""
    params = {
        "latitude": lat,
        "longitude": lon,
        "current_weather": "true",
        "hourly": "temperature_2m,relativehumidity_2m,precipitation,windspeed_10m",
        "timezone": "auto",
    }

    # Build URL with parameters
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

        # Get current hour index for detailed data
        current_time = datetime.fromisoformat(current.get("time", datetime.now().isoformat()))
        hour_index = current_time.hour

        return {
            "city": city_name,
            "temperature": current.get("temperature", 0),
            "windspeed": current.get("windspeed", 0),
            "weather_code": current.get("weathercode", 0),
            "time": current.get("time", ""),
            "humidity": hourly.get("relativehumidity_2m", [0]*24)[hour_index] if hourly else 0,
            "precipitation": hourly.get("precipitation", [0]*24)[hour_index] if hourly else 0,
        }

    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
        print(f"API Error for {city_name}: {e}", file=sys.stderr)
        return None
    except (json.JSONDecodeError, KeyError) as e:
        print(f"Parse Error for {city_name}: {e}", file=sys.stderr)
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
    """Fetch weather for all cities"""
    # Check cache first
    cached = get_cached_data()
    if cached:
        return cached

    weather_data = []
    for city_name, country_code, lat, lon, flag in CITIES:
        weather = fetch_weather(city_name, lat, lon)
        if weather:
            weather["country_code"] = country_code
            weather["flag"] = flag
            weather_data.append(weather)

    # Save to cache if we got data
    if weather_data:
        save_cache(weather_data)

    return weather_data


def create_tooltip(weather_data):
    """Create detailed tooltip with all cities weather"""
    if not weather_data:
        return "Failed to fetch weather data\nRetrying in 10 minutes..."

    from datetime import datetime
    import os

    lines = []
    lines.append("┌─────── WEATHER ───────┐")
    lines.append("│")

    for weather in weather_data:
        desc, icon = get_weather_icon(weather["weather_code"])
        city = weather["city"]
        flag = weather["flag"]
        temp = weather["temperature"]
        wind = weather["windspeed"]
        humidity = weather["humidity"]
        precip = weather["precipitation"]

        lines.append(f"│  {flag}  {city.upper()}")
        lines.append(f"│     {icon}  {desc}")
        lines.append(f"│     🌡️   {temp:.1f}°C")
        lines.append(f"│     💨  {wind:.0f} km/h  │  💧 {humidity:.0f}%")
        if precip > 0:
            lines.append(f"│     🌧️   {precip:.1f} mm")
        lines.append("│")

    # Add World Clocks section
    lines.append("┌──── WORLD CLOCKS ─────┐")

    # Get current times for different zones
    ny_time = datetime.now().astimezone(tz=None).replace(tzinfo=None)
    try:
        import subprocess
        ny_time_str = subprocess.check_output(['date', '+%H:%M'], env={**os.environ, 'TZ': 'America/New_York'}).decode().strip()
        beijing_time_str = subprocess.check_output(['date', '+%H:%M'], env={**os.environ, 'TZ': 'Asia/Shanghai'}).decode().strip()
        vilnius_time_str = subprocess.check_output(['date', '+%H:%M'], env={**os.environ, 'TZ': 'Europe/Vilnius'}).decode().strip()
        cyprus_time_str = subprocess.check_output(['date', '+%H:%M'], env={**os.environ, 'TZ': 'Asia/Nicosia'}).decode().strip()
        costarica_time_str = subprocess.check_output(['date', '+%H:%M'], env={**os.environ, 'TZ': 'America/Costa_Rica'}).decode().strip()

        lines.append(f"│  🇺🇸 New York     {ny_time_str}")
        lines.append(f"│  🇨🇳 Beijing      {beijing_time_str}")
        lines.append(f"│  🇱🇹 Vilnius      {vilnius_time_str}")
        lines.append(f"│  🇨🇾 Cyprus       {cyprus_time_str}")
        lines.append(f"│  🇨🇷 Costa Rica   {costarica_time_str}")
    except:
        pass

    lines.append("└───────────────────────┘")

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
        # Display first city in bar (or rotate through them)
        # For now, show the first city (Lagos)
        first = weather_data[0]
        desc, icon = get_weather_icon(first["weather_code"])
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
