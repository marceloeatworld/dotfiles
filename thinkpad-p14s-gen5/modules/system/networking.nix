# Networking configuration
{ lib, pkgs, ... }:

{
  # Default DNS: dnscrypt-proxy (Quad9)
  # VPN dispatcher script will override this when VPN is active
  networking.nameservers = [ "127.0.0.1" "::1" ];

  # Fix WiFi after suspend (ath11k suspend/resume bug - still present on kernel 6.18)
  # The Qualcomm QCNFA765 (ath11k) driver fails to reconnect after suspend.
  # Upstream patch pending: "wifi: ath11k: bring hibernation support back" (v2)
  # This service reloads the driver module and restarts NetworkManager on resume.
  systemd.services.wifi-resume = {
    description = "Restart WiFi after suspend (ath11k fix)";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '"
        + "sleep 2 && "
        + "${pkgs.kmod}/bin/rmmod ath11k_pci 2>/dev/null; "
        + "sleep 2 && "
        + "${pkgs.kmod}/bin/modprobe ath11k_pci && "
        + "sleep 3 && "
        + "${pkgs.systemd}/bin/systemctl restart NetworkManager"
        + "'";
    };
  };

  # Wireless regulatory database and country code (fixes ath11k regulatory warnings)
  # NOTE: boot.extraModprobeConfig also set in virtualisation.nix (kvm_amd nested) - NixOS merges strings
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="PT"
  '';

  # Enable NetworkManager for easy network management
  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
    # Use default DNS management (dispatcher script handles VPN DNS)
    dns = "default";
  };

  # Disable systemd-resolved (using dnscrypt-proxy instead)
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
    # Required for WireGuard VPN (prevents rpfilter from blocking return traffic)
    checkReversePath = "loose";
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Experimental = false;
      };
    };
  };

  # Bluetooth manager
  services.blueman.enable = true;

  # The blueman package ships a user service with ExecStart already set.
  # NixOS adds a graphical-session drop-in, so reset ExecStart before setting it.
  systemd.user.services.blueman-applet.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.blueman}/bin/blueman-applet"
  ];
}
