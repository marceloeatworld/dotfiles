#!/usr/bin/env python3
"""
Bitcoin Wallet Balance Monitor for Waybar
Derives addresses from zpub keys LOCALLY using embit and checks balances via Mempool.space API
Privacy-focused: zpub keys never leave your machine

IMPROVED VERSION:
- Real gap limit: scans until finding 20 consecutive empty addresses
- Caches derived addresses to avoid re-derivation on rebuild
- Dynamic Python version detection for venv compatibility
"""

import os
import sys
import json
import subprocess
import time
import glob
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from datetime import datetime, timedelta


CONFIG_DIR = Path.home() / ".config/waybar"
ENV_FILE = CONFIG_DIR / ".env"
ENV_EXAMPLE = CONFIG_DIR / ".env.example"

# Cache configuration
CACHE_DIR = Path.home() / ".cache/waybar-bitcoin"
CACHE_FILE = CACHE_DIR / "wallet_cache.json"
CACHE_DURATION = timedelta(hours=24)  # Cache addresses/balances for 24 hours (only price updates every 20 min)

# Real gap limit: stop after finding N consecutive empty addresses
# Increased to 50 to handle wallets with scattered transactions
GAP_LIMIT = 50  # Extended gap limit for better coverage

# Maximum addresses to check per wallet (safety limit)
# Increased to 500 to ensure we catch all addresses
MAX_ADDRESS_INDEX = 500

# Delay between API requests to avoid rate limiting (seconds)
# Increased to 3s to handle double chain scanning (external + change)
API_DELAY = 3.0

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

    # Dynamically find site-packages directory (handles any Python version)
    def add_venv_to_path():
        if python_bin.exists():
            # Find site-packages using glob pattern
            site_packages = glob.glob(str(venv_dir / "lib" / "python*" / "site-packages"))
            if site_packages:
                sys.path.insert(0, site_packages[0])
                return True
        return False

    # Try to add existing venv to path
    add_venv_to_path()

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
                ], stderr=subprocess.DEVNULL)

            # Install embit and requests with uv (much faster than pip)
            subprocess.check_call([
                "uv", "pip", "install",
                "--quiet", "embit", "requests"
            ], env={**os.environ, "VIRTUAL_ENV": str(venv_dir)})

            # Add to path
            add_venv_to_path()

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


def load_cache() -> Optional[Dict]:
    """Load cached addresses and balances if they exist and are fresh"""
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
    """Save addresses and balances to cache file"""
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


def derive_address_at_index(zpub: str, index: int, chain: int = 0) -> Optional[str]:
    """
    Derive a single Bitcoin address from zpub at specified index (BIP84 - Native SegWit)

    Args:
        zpub: Extended public key (zpub...)
        index: Address index to derive
        chain: Chain type (0 = external/receiving, 1 = internal/change)

    Returns:
        Bitcoin address (bc1...) or None on error
    """
    try:
        from embit import bip32
        from embit.script import p2wpkh

        # Parse zpub
        key = bip32.HDKey.from_string(zpub)

        # Derive path chain/index (0 = external, 1 = change)
        child_key = key.derive([chain, index])

        # Get P2WPKH (native SegWit) address
        address = p2wpkh(child_key).address()

        return address
    except Exception as e:
        print(f"Error deriving address at chain {chain}, index {index}: {e}", file=sys.stderr)
        return None


def derive_addresses_from_cache_or_scan(zpub: str, cached_data: Optional[Dict] = None) -> Tuple[List[str], int]:
    """
    Derive addresses intelligently: use cache if available, or scan with gap limit

    Args:
        zpub: Extended public key
        cached_data: Previously cached address data

    Returns:
        Tuple of (list of all addresses to check, max_index)
    """
    if cached_data and cached_data.get('addresses'):
        # Use cached addresses
        addresses = cached_data['addresses']
        max_index = cached_data.get('max_index', len(addresses) - 1)
        print(f"  Using {len(addresses)} cached addresses (up to index {max_index})", file=sys.stderr)

        # Also derive a few more addresses after max_index to detect new usage
        scan_extra = 5  # Check 5 more addresses after cached max
        for i in range(max_index + 1, max_index + scan_extra + 1):
            if i >= MAX_ADDRESS_INDEX:
                break
            addr = derive_address_at_index(zpub, i)
            if addr:
                addresses.append(addr)
                max_index = i

        print(f"  Extended scan to index {max_index}", file=sys.stderr)
        return addresses, max_index
    else:
        # No cache: full gap limit scan
        print(f"  No cache found, performing full gap limit scan...", file=sys.stderr)
        addresses = []
        consecutive_empty = 0
        current_index = 0

        while current_index < MAX_ADDRESS_INDEX and consecutive_empty < GAP_LIMIT:
            # Derive address
            address = derive_address_at_index(zpub, current_index)
            if not address:
                break
            addresses.append(address)

            # Check balance
            balance = get_address_balance(address)
            if balance > 0:
                consecutive_empty = 0
                print(f"    Found balance at index {current_index}: {balance:.8f} BTC", file=sys.stderr)
            else:
                consecutive_empty += 1

            current_index += 1

        max_index = current_index - 1
        print(f"  Scanned up to index {max_index} ({len(addresses)} addresses total)", file=sys.stderr)
        return addresses, max_index


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


def scan_chain(zpub: str, chain: int, cached_data: Optional[Dict] = None) -> Tuple[float, List[str], int, List[int]]:
    """
    Scan a single chain (external or change) for balances

    Args:
        zpub: Extended public key
        chain: 0 for external/receiving, 1 for change/internal
        cached_data: Previously cached data for this chain

    Returns:
        Tuple of (balance, addresses, max_index, active_indices)
    """
    chain_name = "external" if chain == 0 else "change"
    print(f"  Scanning {chain_name} chain (m/84'/0'/0'/{chain}/x)...", file=sys.stderr)

    addresses = []
    consecutive_empty = 0
    current_index = 0
    total_balance = 0.0
    active_indices = []

    # Use cached addresses if available
    if cached_data and cached_data.get('addresses'):
        addresses = cached_data['addresses']
        current_index = len(addresses)
        print(f"    Using {current_index} cached addresses", file=sys.stderr)

    # Scan with gap limit
    while current_index < MAX_ADDRESS_INDEX and consecutive_empty < GAP_LIMIT:
        if current_index < len(addresses):
            address = addresses[current_index]
        else:
            address = derive_address_at_index(zpub, current_index, chain)
            if not address:
                break
            addresses.append(address)

        # Check balance
        balance = get_address_balance(address)
        if balance > 0:
            consecutive_empty = 0
            total_balance += balance
            active_indices.append(current_index)
            print(f"      Found balance at {chain_name} index {current_index}: {balance:.8f} BTC", file=sys.stderr)
        else:
            consecutive_empty += 1

        current_index += 1

    max_index = current_index - 1
    print(f"    {chain_name} chain: {len(addresses)} addresses, balance: {total_balance:.8f} BTC", file=sys.stderr)

    return total_balance, addresses, max_index, active_indices


def get_wallet_balance(zpub: str, cached_data: Optional[Dict] = None) -> Tuple[float, Dict]:
    """
    Get total balance for a wallet from its zpub using intelligent caching
    Scans BOTH external (receiving) and change (internal) chains

    Args:
        zpub: Extended public key
        cached_data: Previously cached address data

    Returns:
        Tuple of (total_balance in BTC, address_data dict for caching)
    """
    total_balance = 0.0

    # Scan external chain (chain 0)
    external_cached = cached_data.get('external') if cached_data else None
    external_balance, external_addrs, external_max, external_active = scan_chain(zpub, 0, external_cached)
    total_balance += external_balance

    # Scan change chain (chain 1)
    change_cached = cached_data.get('change') if cached_data else None
    change_balance, change_addrs, change_max, change_active = scan_chain(zpub, 1, change_cached)
    total_balance += change_balance

    # Prepare cache data
    address_data = {
        'external': {
            'addresses': external_addrs,
            'max_index': external_max,
            'active_indices': sorted(external_active)
        },
        'change': {
            'addresses': change_addrs,
            'max_index': change_max,
            'active_indices': sorted(change_active)
        }
    }

    return total_balance, address_data


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

    # Try to load cached data (skip if --force flag is used)
    cache = None if force_refresh else load_cache()
    use_cache = cache is not None

    if force_refresh:
        print("🔄 Force refresh requested, ignoring cache", file=sys.stderr)

    if use_cache:
        print("✓ Using cached data (addresses + balances)", file=sys.stderr)
        # Extract balances from cache
        for wallet_id, wallet in wallets.items():
            wallet_key = f"wallet_{wallet_id}"
            wallet['balance'] = cache.get('balances', {}).get(wallet_key, 0.0)
    else:
        print("Fetching fresh balances from Mempool.space API...", file=sys.stderr)
        # Calculate balances for each wallet (with API requests)
        cache_balances = {}
        cache_addresses = {}

        for wallet_id, wallet in wallets.items():
            wallet_key = f"wallet_{wallet_id}"
            print(f"\nProcessing {wallet['name']}...", file=sys.stderr)

            try:
                # Get cached address data for this wallet (if exists)
                cached_addr_data = cache.get('addresses', {}).get(wallet_key) if cache else None

                # Get balance with gap limit scanning
                balance, address_data = get_wallet_balance(wallet['zpub'], cached_addr_data)

                wallet['balance'] = balance
                cache_balances[wallet_key] = balance
                cache_addresses[wallet_key] = address_data

                print(f"  Total balance: {balance:.8f} BTC", file=sys.stderr)
            except Exception as e:
                print(f"Error processing wallet {wallet_id}: {e}", file=sys.stderr)
                import traceback
                traceback.print_exc(file=sys.stderr)
                wallet['balance'] = 0.0
                cache_balances[wallet_key] = 0.0
                cache_addresses[wallet_key] = {}

        # Save addresses and balances to cache
        save_cache({
            'addresses': cache_addresses,
            'balances': cache_balances
        })

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
