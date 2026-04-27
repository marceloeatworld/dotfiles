#!/usr/bin/env python3
"""
Polymarket trending markets monitor for Waybar
Displays breaking news and trending prediction markets with probabilities
"""

import json
import sys
import urllib.request
import urllib.error
from datetime import datetime, timedelta
from pathlib import Path

# Configuration
CACHE_FILE = Path.home() / ".cache" / "polymarket-waybar.json"
CACHE_DURATION = timedelta(minutes=5)  # Cache for 5 minutes
API_BASE = "https://gamma-api.polymarket.com"
TIMEOUT = 10  # seconds


def fetch_api(url):
    """Fetch data from Polymarket Gamma API"""
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "Waybar-Polymarket/1.0"}
        )
        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            return json.loads(response.read().decode())
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
        print(f"API Error: {e}", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"JSON Error: {e}", file=sys.stderr)
        return None


def get_cached_data():
    """Get cached data if still valid"""
    if not CACHE_FILE.exists():
        return None

    try:
        with open(CACHE_FILE, 'r') as f:
            data = json.load(f)

        cached_time = datetime.fromisoformat(data['timestamp'])
        if datetime.now() - cached_time < CACHE_DURATION:
            return data['markets']
    except (json.JSONDecodeError, KeyError, ValueError):
        pass

    return None


def save_cache(markets):
    """Save markets to cache"""
    CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(CACHE_FILE, 'w') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'markets': markets
        }, f)


def parse_market_data(event):
    """Parse market data from event"""
    event_markets = event.get('markets', [])
    if not event_markets:
        return None

    # Get the main market (usually the first one)
    market = event_markets[0]

    # Calculate probability from outcomes
    # outcomePrices is a JSON STRING like "[\"0.0185\", \"0.9815\"]"
    outcome_prices_str = market.get('outcomePrices', '["0.5", "0.5"]')

    try:
        # Parse the JSON string to get actual prices
        outcome_prices = json.loads(outcome_prices_str) if isinstance(outcome_prices_str, str) else outcome_prices_str
        yes_price = float(outcome_prices[0]) if len(outcome_prices) > 0 else 0.5
        probability = int(yes_price * 100)
    except (ValueError, IndexError, json.JSONDecodeError):
        probability = 50

    # Get real volume (it's a float or string)
    volume = event.get('volume', 0)
    if isinstance(volume, str):
        try:
            volume = float(volume)
        except ValueError:
            volume = 0

    # Parse creation date
    created_at = event.get('createdAt', '')

    return {
        'title': event.get('title', 'Unknown'),
        'question': market.get('question', event.get('title', 'Unknown')),
        'probability': probability,
        'volume': str(volume),  # Keep as string for format_volume
        'volume24hr': event.get('volume24hr', 0),
        'liquidity': event.get('liquidity', 0),
        'end_date': event.get('endDate', 'Unknown'),
        'slug': event.get('slug', ''),
        'category': event.get('tags', [{}])[0].get('label', 'General') if event.get('tags') else 'General',
        'tags': [tag.get('label', '') for tag in event.get('tags', [])],
        'created_at': created_at
    }


def fetch_trending_markets():
    """Fetch and organize markets into Bitcoin, Trending, Breaking, and New sections"""
    # Check cache first
    cached = get_cached_data()
    if cached:
        return cached

    # Fetch active markets - get more to filter properly
    url = f"{API_BASE}/events?closed=false&active=true&limit=80"
    data = fetch_api(url)

    if not data:
        return {}

    all_markets = []

    for event in data:
        market_data = parse_market_data(event)
        if not market_data:
            continue
        all_markets.append(market_data)

    # === SECTION 1: BITCOIN ===
    bitcoin_markets = []
    for m in all_markets:
        question_lower = m['question'].lower()
        if 'bitcoin' in question_lower or 'btc' in question_lower:
            bitcoin_markets.append(m)
    # Sort Bitcoin by volume24hr
    bitcoin_markets.sort(key=lambda m: float(m.get('volume24hr', 0)), reverse=True)

    # Track shown markets to avoid duplicates
    shown_slugs = set(m['slug'] for m in bitcoin_markets if m.get('slug'))

    # === SECTION 2: TRENDING ===
    # Top markets by 24h volume (all categories) - exclude already shown
    trending_markets = [m for m in all_markets if m.get('slug') not in shown_slugs]
    trending_markets.sort(key=lambda m: float(m.get('volume24hr', 0)), reverse=True)
    shown_slugs.update(m['slug'] for m in trending_markets[:8] if m.get('slug'))

    # === SECTION 3: ECONOMY ===
    # Markets related to economy, business, finance - exclude already shown
    economy_markets = []
    for m in all_markets:
        if m.get('slug') not in shown_slugs:
            tags_lower = [tag.lower() for tag in m.get('tags', [])]
            # Check if market has economy-related tags
            if any(tag in tags_lower for tag in ['economy', 'business', 'fed', 'fed rates', 'finance', 'economic policy', 'gold', 'stocks', 'commodities']):
                economy_markets.append(m)
    # Sort by volume24hr
    economy_markets.sort(key=lambda m: float(m.get('volume24hr', 0)), reverse=True)
    shown_slugs.update(m['slug'] for m in economy_markets[:6] if m.get('slug'))

    # === SECTION 4: WORLD ===
    # Markets related to world events, geopolitics - exclude already shown
    world_markets = []
    for m in all_markets:
        if m.get('slug') not in shown_slugs:
            tags_lower = [tag.lower() for tag in m.get('tags', [])]
            # Check if market has world/geopolitics-related tags
            if any(tag in tags_lower for tag in ['world', 'geopolitics', 'macro geopolitics', 'foreign policy', 'middle east', 'ukraine', 'russia', 'iran', 'israel', 'gaza', 'nato']):
                world_markets.append(m)
    # Sort by volume24hr
    world_markets.sort(key=lambda m: float(m.get('volume24hr', 0)), reverse=True)
    shown_slugs.update(m['slug'] for m in world_markets[:6] if m.get('slug'))

    # === SECTION 5: NEW ===
    # Most recently created markets - exclude already shown
    new_markets = [m for m in all_markets if m.get('created_at') and m.get('slug') not in shown_slugs]
    new_markets.sort(key=lambda m: m.get('created_at', ''), reverse=True)

    result = {
        'bitcoin': bitcoin_markets[:6],
        'trending': trending_markets[:8],
        'economy': economy_markets[:6],
        'world': world_markets[:6],
        'new': new_markets[:6]
    }

    # Save to cache
    save_cache(result)
    return result


def escape_html(text):
    """Escape HTML entities for Waybar tooltip"""
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def load_theme_colors():
    """Load theme colors from Nix-generated file"""
    colors = {"FG": "#d4d4d4", "DIM": "#9d9d9d", "ACCENT": "#d4c080",
              "RED": "#d08080", "GREEN": "#90c090", "BLUE": "#90a8c8"}
    theme_file = Path.home() / ".config/waybar/scripts/theme-colors.sh"
    if theme_file.exists():
        for line in theme_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, val = line.split('=', 1)
                k = k.strip().replace('C_', '')
                colors[k] = val.strip().strip('"')
    return colors

C = load_theme_colors()

def h(text):
    return f"<span color='{C['ACCENT']}'><b>{text}</b></span>"
def v(text):
    return f"<span color='{C['FG']}'>{text}</span>"
def d(text):
    return f"<span color='{C['DIM']}'>{text}</span>"
def g(text):
    return f"<span color='{C['GREEN']}'>{text}</span>"
def r(text):
    return f"<span color='{C['RED']}'>{text}</span>"


def format_volume(volume_str):
    """Format volume string to readable format"""
    try:
        volume = float(volume_str)
        if volume >= 1_000_000:
            return f"${volume/1_000_000:.1f}M"
        elif volume >= 1_000:
            return f"${volume/1_000:.1f}K"
        else:
            return f"${volume:.0f}"
    except (ValueError, TypeError):
        return "$0"


def prob_color(prob):
    """Color probability based on value"""
    if prob >= 70:
        return g(f"{prob}%")
    elif prob <= 30:
        return r(f"{prob}%")
    return v(f"{prob}%")


def render_section(title, markets, max_items=4):
    """Render a section with Pango markup"""
    if not markets:
        return []
    lines = ["", h(f"  {title}"), ""]
    for market in markets[:max_items]:
        prob = market['probability']
        title_text = escape_html(market['question'][:50])
        vol24h = format_volume(str(market.get('volume24hr', 0)))
        lines.append(f"{prob_color(prob)}  {v(title_text)}")
        lines.append(f"     {d(vol24h)}")
    return lines


def create_tooltip(markets_data):
    """Create Pango markup tooltip"""
    if not markets_data:
        return "No markets available"

    lines = [h("  POLYMARKET")]

    lines.extend(render_section("₿ BITCOIN", markets_data.get('bitcoin', [])))
    lines.extend(render_section("📈 TRENDING", markets_data.get('trending', [])))
    lines.extend(render_section("💰 ECONOMY", markets_data.get('economy', [])))
    lines.extend(render_section("🌍 WORLD", markets_data.get('world', [])))
    lines.extend(render_section("🆕 NEW", markets_data.get('new', []), 3))

    return "\n".join(lines)


def main():
    """Main entry point"""
    markets_data = fetch_trending_markets()

    if not markets_data:
        output = {
            "text": "📊",
            "tooltip": "Failed to fetch Polymarket data\nRetrying in 5 minutes...",
            "class": "polymarket-error"
        }
    else:
        # Just show emoji in bar, all details in tooltip
        output = {
            "text": "📊",
            "tooltip": create_tooltip(markets_data),
            "class": "polymarket"
        }

    print(json.dumps(output))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        error_output = {
            "text": "📊 ERR",
            "tooltip": f"Polymarket Error:\n{str(e)}",
            "class": "polymarket-error"
        }
        print(json.dumps(error_output))
        sys.exit(1)
