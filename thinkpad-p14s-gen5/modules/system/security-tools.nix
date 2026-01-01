# Security tools system configuration
# ALL security tools consolidated here (packages + permissions)
# Home module (programs/security-tools.nix) contains only aliases and documentation
{ pkgs, pkgs-unstable, config, ... }:

{
  # Wireshark: Enable packet capture for non-root users
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;  # Full GUI version
  };

  # Add user to wireshark group for packet capture permissions
  users.users.marcelo.extraGroups = [ "wireshark" ];

  # Install ALL security tools system-wide
  environment.systemPackages = (with pkgs; [
    # ============================================
    # NETWORK ANALYSIS
    # ============================================
    nmap           # Network scanner and security auditing
    zenmap         # Zenmap GUI for nmap
    tcpdump        # Command-line packet analyzer
    ngrep          # Network grep - search network packets

    # ============================================
    # WIRELESS SECURITY
    # ============================================
    # Core tools
    aircrack-ng    # WiFi security auditing suite (WEP/WPA/WPA2/WPA3)
    wifite2        # Automated wireless attack tool

    # WPS attacks
    reaverwps      # WPS cracking tool (Reaver)
    pixiewps       # PixieDust WPS attack

    # Monitoring & Analysis
    kismet         # Wireless network detector and sniffer

    # Additional tools
    mdk4           # WiFi DoS/stress testing tool
    cowpatty       # WPA-PSK dictionary attack

    # Fake AP / Evil Twin
    hostapd        # Create rogue access points
    dnsmasq        # DHCP/DNS server for fake AP

    # ============================================
    # PASSWORD CRACKING
    # ============================================
    hashcat-utils  # Utilities for hashcat
    john           # John the Ripper password cracker

    # ============================================
    # WEB APPLICATION TESTING
    # ============================================
    sqlmap         # Automatic SQL injection and database takeover
    nikto          # Web server scanner
    dirb           # Web content scanner
    hydra          # Network authentication cracker

    # ============================================
    # DATA ANALYSIS & CRYPTO
    # ============================================
    cyberchef      # Cyber Swiss Army Knife - web-based data analysis

    # ============================================
    # RECONNAISSANCE
    # ============================================
    whois          # Domain information lookup
    dnsutils       # dig, nslookup, etc.

    # ============================================
    # SSL/TLS TESTING
    # ============================================
    testssl        # Test SSL/TLS encryption
    sslscan        # SSL/TLS scanner

    # ============================================
    # WORDLISTS
    # ============================================
    seclists       # Security lists for security testing
    crunch         # Wordlist generator
  ]) ++ (with pkgs-unstable; [
    # UNSTABLE versions (newer features!)
    hcxtools       # Convert captures to hashcat format
    hcxdumptool    # Capture PMKID without handshake
    bettercap      # Modern MITM framework
    hashcat        # GPU-accelerated password cracker
  ]);

  # NOTE: ROCm OpenCL for hashcat GPU is configured in amd-optimizations.nix
}
