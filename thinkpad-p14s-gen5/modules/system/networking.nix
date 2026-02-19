# Networking configuration
{ pkgs, ... }:

{
  # Default DNS: dnscrypt-proxy2 (Quad9)
  # VPN dispatcher script will override this when VPN is active
  networking.nameservers = [ "127.0.0.1" "::1" ];

  # NOTE: ath11k wifi-resume service removed - no longer needed on kernel 6.16+
  # The 4WAY_HANDSHAKE_TIMEOUT bug was fixed in kernel 6.16.
  # Current kernel: 6.18 (Zen). Keeping as reference in case of regression:
  # systemd.services.wifi-resume = {
  #   description = "Restart WiFi after suspend (ath11k fix)";
  #   after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
  #   wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.kmod}/bin/rmmod ath11k_pci && sleep 1 && ${pkgs.kmod}/bin/modprobe ath11k_pci'";
  #   };
  # };

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
}
