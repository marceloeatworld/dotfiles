# Networking configuration
{ ... }:

{
  # Default DNS: dnscrypt-proxy2 (Quad9)
  # VPN dispatcher script will override this when VPN is active
  networking.nameservers = [ "127.0.0.1" "::1" ];

  # Enable NetworkManager for easy network management
  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
    # Use default DNS management (dispatcher script handles VPN DNS)
    dns = "default";
  };

  # Disable systemd-resolved (using dnscrypt-proxy2 instead)
  services.resolved.enable = false;

  # DNS over HTTPS with dnscrypt-proxy (bypasses router DNS hijacking)
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;

      # European DNS servers with ad-blocking, malware blocking, and privacy
      # AdGuard (Cyprus), Mullvad (Sweden), Quad9 (Europe anycast)
      server_names = [
        "adguard-dns"                          # Cyprus - Ads + trackers + malware blocking
        "mullvad-adblock-doh"                  # Sweden - Aggressive ad-blocking
        "quad9-dnscrypt-ip4-filter-pri"        # Europe anycast - Malware + phishing blocking
        "quad9-dnscrypt-ip4-filter-alt"        # Europe anycast - Backup
      ];

      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];

      # Source list of public resolvers
      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 72;
      };
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # Bluetooth manager
  services.blueman.enable = true;

  # OpenSnitch - Application-level firewall
  # Monitors and controls outgoing connections per application
  # Works alongside networking.firewall (which handles incoming connections)
  services.opensnitch = {
    enable = true;
    settings = {
      DefaultAction = "allow";  # No pop-ups, everything allowed by default
      DefaultDuration = "always";  # Rules persist forever (not just until reboot)
      LogLevel = 1;             # Log connections (viewable in UI)
    };
  };
}
