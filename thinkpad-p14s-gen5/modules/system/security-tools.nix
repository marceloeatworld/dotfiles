# Security tools system configuration
# Provides system-level permissions and configurations for security audit tools
{ pkgs, pkgs-unstable, config, ... }:

{
  # Wireshark: Enable packet capture for non-root users
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;  # Full GUI version
  };

  # Add user to wireshark group for packet capture permissions
  users.users.marcelo.extraGroups = [ "wireshark" ];

  # Install system-wide security tools that benefit from system integration
  environment.systemPackages = (with pkgs; [
    # Network analysis
    nmap           # Network scanner and security auditing
    zenmap         # Zenmap GUI for nmap

    # Wireless security - Core tools
    aircrack-ng    # WiFi security auditing suite (WEP/WPA/WPA2/WPA3) - v1.7
    wifite2        # Automated wireless attack tool (v2.7.0)

    # Wireless security - WPS attacks
    reaverwps      # WPS cracking tool (Reaver)
    pixiewps       # PixieDust WPS attack

    # Wireless security - Monitoring & Analysis
    kismet         # Wireless network detector and sniffer

    # Wireless security - Additional tools
    mdk4           # WiFi DoS/stress testing tool
    cowpatty       # WPA-PSK dictionary attack

    # Fake AP / Evil Twin
    hostapd        # Create rogue access points
    dnsmasq        # DHCP/DNS server for fake AP

    # Password cracking with GPU support
    hashcat-utils  # Utilities for hashcat
    john           # John the Ripper password cracker
  ]) ++ (with pkgs-unstable; [
    # UNSTABLE versions (newer features!)
    hcxtools       # Convert captures to hashcat format (v7.0.1 - NEWER!)
    hcxdumptool    # Capture PMKID without handshake (v7.0.1 - NEWER!)
    bettercap      # Modern MITM framework (v2.41.4 - NEWER!)
    hashcat        # GPU-accelerated password cracker (v7.1.2 - MUCH NEWER!)
  ]);

  # Enable OpenCL for AMD GPU (Radeon 780M) - Required for hashcat GPU acceleration
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd      # ROCm OpenCL ICD for AMD GPUs
  ];

  # Optional: Enable monitoring capabilities for aircrack-ng
  # Uncomment if you need to put WiFi adapters in monitor mode
  # boot.extraModprobeConfig = ''
  #   options cfg80211 ieee80211_regdom=PT
  # '';
}
