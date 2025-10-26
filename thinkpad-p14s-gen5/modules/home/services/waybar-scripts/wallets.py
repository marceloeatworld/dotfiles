#!/usr/bin/env python3
"""
Bitcoin Wallet Balance Monitor for Waybar
Derives addresses from zpub keys LOCALLY using embit and checks balances via Mempool.space API
Privacy-focused: zpub keys never leave your machine
"""

import os
import sys
import json
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Tuple
from datetime import datetime, timedelta


CONFIG_DIR = Path.home() / ".config/waybar"
ENV_FILE = CONFIG_DIR / ".env"
ENV_EXAMPLE = CONFIG_DIR / ".env.example"

# Cache configuration
CACHE_DIR = Path.home() / ".cache/waybar-bitcoin"
CACHE_FILE = CACHE_DIR / "balances.json"
CACHE_DURATION = timedelta(hours=1)  # Cache balances for 1 hour

# Number of addresses to derive per wallet (increased to catch all used addresses)
ADDRESS_GAP_LIMIT = 50

# Delay between API requests to avoid rate limiting (seconds)
# With 6 wallets × 50 addresses = 300 requests, 2.5s delay = ~12 minutes total
# But cache makes subsequent requests instant!
API_DELAY = 2.5

# Lazy import for requests (imported after dependencies are installed)
_requests = None

def get_requests():
    """Get requests module, import if needed"""
    global _requests
    if _requests is None:
        import requests as req
        _requests = req
    return _requests


def ensure_dependencies():
    """Ensure embit is installed in venv using uv, install if needed"""
    venv_dir = Path.home() / ".local/share/waybar-bitcoin-venv"
    python_bin = venv_dir / "bin" / "python3"

    # Add venv to path if it exists
    if python_bin.exists():
        sys.path.insert(0, str(venv_dir / "lib" / "python3.13" / "site-packages"))

    try:
        import embit
        import requests
        return True
    except ImportError:
        print("Installing embit with uv (fast Python package manager)...", file=sys.stderr)
        try:
            # Create venv with uv if doesn't exist
            if not venv_dir.exists():
                subprocess.check_call([
                    "uv", "venv", str(venv_dir)
                ])

            # Install embit and requests with uv (much faster than pip)
            subprocess.check_call([
                "uv", "pip", "install",
                "--quiet", "embit", "requests"
            ], env={**os.environ, "VIRTUAL_ENV": str(venv_dir)})

            # Add to path
            sys.path.insert(0, str(venv_dir / "lib" / "python3.13" / "site-packages"))

            print("✓ embit installed with uv", file=sys.stderr)
            return True
        except Exception as e:
            print(f"Failed to install embit: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc(file=sys.stderr)
            return False


def load_env() -> Dict[str, str]:
    """Load environment variables from .env file"""
    if not ENV_FILE.exists():
        return {}

    env_vars = {}
    with open(ENV_FILE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip().strip('"').strip("'")
    return env_vars


def load_cache() -> Dict:
    """Load cached balances if they exist and are fresh"""
    if not CACHE_FILE.exists():
        return None

    try:
        with open(CACHE_FILE, 'r') as f:
            cache = json.load(f)

        # Check if cache is still fresh
        cache_time = datetime.fromisoformat(cache.get('timestamp', '2000-01-01'))
        if datetime.now() - cache_time < CACHE_DURATION:
            return cache
        else:
            print(f"Cache expired (age: {datetime.now() - cache_time})", file=sys.stderr)
            return None
    except Exception as e:
        print(f"Error loading cache: {e}", file=sys.stderr)
        return None


def save_cache(data: Dict):
    """Save balances to cache file"""
    try:
        # Ensure cache directory exists
        CACHE_DIR.mkdir(parents=True, exist_ok=True)

        # Add timestamp
        data['timestamp'] = datetime.now().isoformat()

        with open(CACHE_FILE, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"✓ Cache saved to {CACHE_FILE}", file=sys.stderr)
    except Exception as e:
        print(f"Error saving cache: {e}", file=sys.stderr)


def derive_addresses_from_zpub(zpub: str, count: int = ADDRESS_GAP_LIMIT) -> List[str]:
    """
    Derive Bitcoin addresses from zpub (BIP84 - Native SegWit) LOCALLY

    Args:
        zpub: Extended public key (zpub...)
        count: Number of addresses to derive

    Returns:
        List of Bitcoin addresses (bc1...)
    """
    try:
        from embit import bip32
        from embit.script import p2wpkh

        # Parse zpub
        key = bip32.HDKey.from_string(zpub)

        addresses = []
        # Derive external chain addresses (0/i)
        for i in range(count):
            # Derive path 0/i (external chain, address index)
            child_key = key.derive([0, i])
            # Get P2WPKH (native SegWit) address
            address = p2wpkh(child_key).address()
            addresses.append(address)

        return addresses
    except Exception as e:
        print(f"Error deriving addresses from zpub: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return []


def get_address_balance(address: str) -> float:
    """
    Get balance for a single Bitcoin address via Mempool.space API

    Args:
        address: Bitcoin address (bc1...)

    Returns:
        Balance in BTC
    """
    try:
        requests = get_requests()

        # Add delay before API request to avoid rate limiting
        time.sleep(API_DELAY)

        url = f"https://mempool.space/api/address/{address}"
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        data = response.json()

        # Balance is in satoshis, convert to BTC
        chain_stats = data.get('chain_stats', {})
        funded = chain_stats.get('funded_txo_sum', 0)
        spent = chain_stats.get('spent_txo_sum', 0)
        balance_sats = funded - spent

        return balance_sats / 100_000_000  # Convert satoshis to BTC
    except Exception as e:
        print(f"Error fetching balance for {address}: {e}", file=sys.stderr)
        return 0.0


def get_wallet_balance(zpub: str) -> float:
    """
    Get total balance for a wallet from its zpub

    Args:
        zpub: Extended public key

    Returns:
        Total balance in BTC
    """
    addresses = derive_addresses_from_zpub(zpub)
    if not addresses:
        return 0.0

    total_balance = 0.0
    for addr in addresses:
        balance = get_address_balance(addr)
        if balance > 0:
            total_balance += balance

    return total_balance


def get_btc_prices() -> Tuple[float, float]:
    """
    Get current BTC price in USD and EUR from Coinbase API

    Returns:
        Tuple of (usd_price, eur_price)
    """
    try:
        requests = get_requests()
        # Fetch USD price from Coinbase
        usd_response = requests.get("https://api.coinbase.com/v2/prices/BTC-USD/spot", timeout=10)
        usd_response.raise_for_status()
        usd_data = usd_response.json()
        usd_price = float(usd_data['data']['amount'])

        # Fetch EUR price from Coinbase
        eur_response = requests.get("https://api.coinbase.com/v2/prices/BTC-EUR/spot", timeout=10)
        eur_response.raise_for_status()
        eur_data = eur_response.json()
        eur_price = float(eur_data['data']['amount'])

        return (usd_price, eur_price)
    except Exception as e:
        print(f"Error fetching BTC prices: {e}", file=sys.stderr)
        return (0.0, 0.0)


def format_number(num: float, suffix: str = "") -> str:
    """Format number with K/M suffix for large values"""
    if num >= 1_000_000:
        return f"{num/1_000_000:.2f}M{suffix}"
    elif num >= 1_000:
        return f"{num/1_000:.1f}K{suffix}"
    else:
        return f"{num:.2f}{suffix}"


def main():
    """Main function to generate Waybar output"""

    # Check for --force flag to force cache refresh
    force_refresh = "--force" in sys.argv

    # Ensure dependencies are installed
    if not ensure_dependencies():
        print(json.dumps({
            "text": "⚠️",
            "tooltip": "Failed to install embit\nCheck logs: journalctl -xe",
            "class": "error"
        }))
        return

    # Check if .env exists
    if not ENV_FILE.exists():
        if ENV_EXAMPLE.exists():
            tooltip = f"⚠️ Create {ENV_FILE}\n\nCopy {ENV_EXAMPLE.name} to .env and add your zpub keys"
        else:
            tooltip = f"⚠️ Create {ENV_FILE}\n\nAdd your wallet zpub keys"

        print(json.dumps({
            "text": "₿ --",
            "tooltip": tooltip,
            "class": "warning"
        }))
        return

    # Load wallets from .env
    env = load_env()
    wallets = {}

    # Find all wallet zpub keys
    i = 1
    while True:
        zpub_key = f"WALLET_{i}_ZPUB"
        name_key = f"WALLET_{i}_NAME"

        if zpub_key not in env:
            break

        wallets[i] = {
            'zpub': env[zpub_key],
            'name': env.get(name_key, f"Wallet {i}"),
            'balance': 0.0
        }
        i += 1

    if not wallets:
        print(json.dumps({
            "text": "₿ 0",
            "tooltip": "No wallets configured in .env",
            "class": "empty"
        }))
        return

    # Try to load cached balances (skip if --force flag is used)
    cache = None if force_refresh else load_cache()
    use_cache = cache is not None

    if force_refresh:
        print("🔄 Force refresh requested, ignoring cache", file=sys.stderr)

    if use_cache:
        print("✓ Using cached balances", file=sys.stderr)
        # Extract balances from cache
        for wallet_id, wallet in wallets.items():
            wallet_key = f"wallet_{wallet_id}"
            wallet['balance'] = cache.get('balances', {}).get(wallet_key, 0.0)
    else:
        print("Fetching fresh balances from Mempool.space API...", file=sys.stderr)
        # Calculate balances for each wallet (with API requests)
        cache_balances = {}
        for wallet_id, wallet in wallets.items():
            try:
                balance = get_wallet_balance(wallet['zpub'])
                wallet['balance'] = balance
                cache_balances[f"wallet_{wallet_id}"] = balance
            except Exception as e:
                print(f"Error processing wallet {wallet_id}: {e}", file=sys.stderr)
                wallet['balance'] = 0.0
                cache_balances[f"wallet_{wallet_id}"] = 0.0

        # Save balances to cache
        save_cache({'balances': cache_balances})

    # Calculate total BTC
    total_btc = sum(wallet['balance'] for wallet in wallets.values())

    # Get BTC prices
    usd_price, eur_price = get_btc_prices()

    # Calculate fiat values
    total_usd = total_btc * usd_price
    total_eur = total_btc * eur_price

    # Format display text - show in BTC with 2 decimals (rounded)
    btc_display = f"{total_btc:.2f}₿"

    # Build tooltip with individual wallet balances
    tooltip_lines = [f"₿ Total Balance: {total_btc:.8f} BTC"]
    tooltip_lines.append(f"💵 USD: ${format_number(total_usd)}")
    tooltip_lines.append(f"💶 EUR: €{format_number(total_eur)}")
    tooltip_lines.append("")
    tooltip_lines.append("─" * 40)
    tooltip_lines.append("")

    for wallet_id, wallet in sorted(wallets.items()):
        wallet_usd = wallet['balance'] * usd_price
        wallet_eur = wallet['balance'] * eur_price

        tooltip_lines.append(f"📌 {wallet['name']}")
        tooltip_lines.append(f"   BTC: {wallet['balance']:.8f}")
        tooltip_lines.append(f"   USD: ${format_number(wallet_usd)}")
        tooltip_lines.append(f"   EUR: €{format_number(wallet_eur)}")
        tooltip_lines.append("")

    tooltip_lines.append("─" * 40)
    tooltip_lines.append(f"📊 BTC Price: ${usd_price:,.0f} / €{eur_price:,.0f}")
    tooltip_lines.append("")
    tooltip_lines.append("🔒 Privacy: addresses derived locally")

    tooltip = "\n".join(tooltip_lines)

    # Output Waybar JSON
    output = {
        "text": btc_display,
        "tooltip": tooltip,
        "class": "crypto"
    }

    print(json.dumps(output))


if __name__ == "__main__":
    main()
