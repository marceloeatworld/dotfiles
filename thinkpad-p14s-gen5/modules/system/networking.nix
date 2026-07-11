# Networking configuration
{ lib, pkgs, ... }:

{
  # Default DNS: dnscrypt-proxy (AdGuard/Mullvad)
  # VPN dispatcher script will override this when VPN is active
  networking.nameservers = [ "127.0.0.1" "::1" ];

  # Fix WiFi after suspend (ath11k suspend/resume bug - last verified on kernel 6.18; retest on current kernel before removing)
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

  # Wireless regulatory database and country code (sets the global regdomain to PT).
  # This does NOT silence the ath11k "failed to process regulatory info -22"
  # messages: the WCN6855 phy is self-managed and ignores the cfg80211 regdom.
  # NOTE: boot.extraModprobeConfig also set in virtualisation.nix (kvm_amd nested) - NixOS merges strings
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="PT"
  '';

  # Enable NetworkManager for easy network management
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
    # /etc/resolv.conf is owned by vpn-dns-switch.nix and points to dnscrypt-proxy
    # unless a VPN or captive portal is active. Prevent NetworkManager/openresolv
    # from competing with that dispatcher-managed file.
    dns = "none";
    settings.connectivity = {
      enabled = true;
      uri = "http://nmcheck.gnome.org/check_network_status.txt";
      response = "NetworkManager is online";
      interval = 30;
      timeout = 10;
    };
  };

  # Disable systemd-resolved (using dnscrypt-proxy instead)
  services.resolved.enable = false;

  # DNS over HTTPS with dnscrypt-proxy (bypasses router DNS hijacking)
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;

      # Transparent, filtered DNS providers with public filtering/source code.
      # Keep the pool limited to providers explicitly trusted here.
      server_names = [
        "adguard-dns"         # Ads, trackers, and malware blocking
        "mullvad-adblock-doh" # Ads and trackers; public blocklist configuration
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
    powerOnBoot = true;
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
