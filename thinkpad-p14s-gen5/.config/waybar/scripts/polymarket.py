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

    # === SECTION 2: TRENDING ===
    # Top markets by 24h volume (all categories)
    trending_markets = sorted(all_markets, key=lambda m: float(m.get('volume24hr', 0)), reverse=True)

    # === SECTION 3: BREAKING ===
    # Markets with extreme probabilities (>75% or <25%) indicating strong consensus
    breaking_markets = [m for m in all_markets if m['probability'] >= 75 or m['probability'] <= 25]
    # Sort breaking by volume24hr (most active breaking news)
    breaking_markets.sort(key=lambda m: float(m.get('volume24hr', 0)), reverse=True)

    # === SECTION 4: NEW ===
    # Most recently created markets
    new_markets = [m for m in all_markets if m.get('created_at')]
    new_markets.sort(key=lambda m: m.get('created_at', ''), reverse=True)

    result = {
        'bitcoin': bitcoin_markets[:6],
        'trending': trending_markets[:8],
        'breaking': breaking_markets[:6],
        'new': new_markets[:6]
    }

    # Save to cache
    save_cache(result)
    return result


def escape_html(text):
    """Escape HTML entities for Waybar tooltip"""
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


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


def create_tooltip(markets_data):
    """Create detailed tooltip with market information"""
    if not markets_data:
        return "No markets available"

    lines = []
    lines.append("┌─────── POLYMARKET ────────┐")
    lines.append("│")

    # === BITCOIN SECTION ===
    bitcoin_markets = markets_data.get('bitcoin', [])
    if bitcoin_markets:
        lines.append("│  ₿  BITCOIN")
        for market in bitcoin_markets[:5]:
            prob = market['probability']
            emoji = "🟢" if prob >= 60 else "🔴" if prob <= 40 else "⚪"
            title = escape_html(market['question'][:48])
            vol24h = format_volume(str(market.get('volume24hr', 0)))
            lines.append(f"│     {emoji} {prob}% - {title}")
            lines.append(f"│        Vol 24h: {vol24h}")
        lines.append("│")

    # === TRENDING SECTION ===
    trending_markets = markets_data.get('trending', [])
    if trending_markets:
        lines.append("│  📈  TRENDING")
        for market in trending_markets[:5]:
            prob = market['probability']
            emoji = "🔥"
            title = escape_html(market['question'][:48])
            vol24h = format_volume(str(market.get('volume24hr', 0)))
            lines.append(f"│     {emoji} {prob}% - {title}")
            lines.append(f"│        Vol 24h: {vol24h}")
        lines.append("│")

    # === BREAKING SECTION ===
    breaking_markets = markets_data.get('breaking', [])
    if breaking_markets:
        lines.append("│  🚨  BREAKING")
        for market in breaking_markets[:5]:
            prob = market['probability']
            emoji = "📈" if prob >= 75 else "📉"
            title = escape_html(market['question'][:48])
            vol24h = format_volume(str(market.get('volume24hr', 0)))
            cat = escape_html(market['category'])
            lines.append(f"│     {emoji} {prob}% - {title}")
            lines.append(f"│        {cat}  │  Vol 24h: {vol24h}")
        lines.append("│")

    # === NEW SECTION ===
    new_markets = markets_data.get('new', [])
    if new_markets:
        lines.append("│  🆕  NEW")
        for market in new_markets[:5]:
            prob = market['probability']
            title = escape_html(market['question'][:48])
            vol24h = format_volume(str(market.get('volume24hr', 0)))
            lines.append(f"│     • {prob}% - {title}")
            lines.append(f"│        Vol 24h: {vol24h}")

    lines.append("│")
    lines.append("└───────────────────────────┘")

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
