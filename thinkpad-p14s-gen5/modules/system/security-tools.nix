# Security tools system configuration
# ALL security tools consolidated here (packages + permissions)
# Home module (programs/security-packages.nix) contains only aliases and documentation
{ pkgs, lib, ... }:

{
  # Wireshark: Enable packet capture for non-root users
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;  # Full GUI version
  };

  # Add user to wireshark group for packet capture permissions
  users.users.marcelo.extraGroups = [ "wireshark" ];

  # Tor SOCKS on 127.0.0.1:9050 for torsocks, proxychains4 and
  # `curl --socks5-hostname`. Also puts `tor` and `torsocks` on PATH.
  services.tor = {
    enable = true;
    client.enable = true;
    torsocks.enable = true;
  };
  # On demand only: `sudo systemctl start tor`. Drop this line to start at boot.
  systemd.services.tor.wantedBy = lib.mkForce [ ];

  # proxychains4 with /etc/proxychains.conf (strict chain, proxy_dns by default).
  # The module adds the Tor proxy itself as socks4; socks5 matches the Kali image.
  programs.proxychains = {
    enable = true;
    package = pkgs.proxychains-ng;
    proxies.torproxy = {
      enable = true;
      type = "socks5";
      host = "127.0.0.1";
      port = 9050;
    };
  };

  # Install ALL security tools system-wide
  environment.systemPackages = (with pkgs; [
    # ============================================
    # NETWORK ANALYSIS
    # ============================================
    nmap           # Network scanner and security auditing
    tcpdump        # Command-line packet analyzer
    ngrep          # Network grep - search network packets
    python3Packages.shodan # Official Shodan CLI (key: sops shodan_api_key)
    uncover        # Exposed-host search across Shodan and other engines
    smap           # Nmap-style output from Shodan InternetDB (no key)

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
    nuclei         # Template-based vulnerability scanner
    thc-hydra      # Network authentication cracker (provides the `hydra` binary)

    # ============================================
    # STEGANOGRAPHY
    # ============================================
    stegseek       # Fast steghide cracker
    # ST3GG - All-in-one steganography toolkit (100+ encoding techniques)
    # Commands: st3gg (CLI), st3gg-tui (TUI), st3gg-web (WebUI)
    (let
      st3gg-python = pkgs.python313.withPackages (ps: with ps; [
        pillow numpy typer rich textual nicegui fastapi cryptography
      ]);
    in pkgs.stdenv.mkDerivation {
      pname = "st3gg";
      version = "unstable";
      src = pkgs.fetchFromGitHub {
        owner = "elder-plinius";
        repo = "ST3GG";
        rev = "7db09389507f90025e728a9516e155ebcf8dbeaf";
        sha256 = "sha256-/HE0CufdEdyQlyg6D1BJNNa2lUSoC1/wmtS2Sr1pkQs=";
      };
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share/st3gg $out/bin
        cp -r . $out/share/st3gg/
        # CLI wrapper
        cat > $out/bin/st3gg <<SCRIPT
        #!/bin/sh
        exec ${st3gg-python}/bin/python $out/share/st3gg/cli.py "\$@"
        SCRIPT
        chmod +x $out/bin/st3gg
        # TUI wrapper
        cat > $out/bin/st3gg-tui <<SCRIPT
        #!/bin/sh
        exec ${st3gg-python}/bin/python $out/share/st3gg/tui.py "\$@"
        SCRIPT
        chmod +x $out/bin/st3gg-tui
        # WebUI wrapper
        cat > $out/bin/st3gg-web <<SCRIPT
        #!/bin/sh
        exec ${st3gg-python}/bin/python $out/share/st3gg/webui.py "\$@"
        SCRIPT
        chmod +x $out/bin/st3gg-web
      '';
    })

    # ============================================
    # DATA ANALYSIS & CRYPTO
    # ============================================
    cyberchef      # Cyber Swiss Army Knife - web-based data analysis

    # ============================================
    # RECONNAISSANCE
    # ============================================
    whois          # Domain information lookup
    # dnsutils (dig/nslookup) already installed in hosts/thinkpad/configuration.nix

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
    hcxtools       # Convert captures to hashcat format
    hcxdumptool    # Capture PMKID without handshake
    bettercap      # Modern MITM framework
    hashcat        # GPU-accelerated password cracker

    # ============================================
    # REVERSE ENGINEERING
    # ============================================
    # Ghidra itself is installed via the firejail wrapper in security.nix;
    # Claude drives Ghidra headless through the rea MCP server (claude-code.nix)
    moria          # Firmware identification and extraction (filesystems, kernels, keys)
    binwalk        # Firmware analysis and extraction (signature scan, entropy)
    siglens        # Static artifact/YARA analysis; Windows-only engines unavailable
    rea            # App/binary analysis CLI and MCP server

    # ============================================
    # AI SECURITY AGENTS
    # ============================================
    skillspector   # NVIDIA scanner for agent skills: `skillspector scan <dir> --no-llm`
    strix          # AI pentest agent; its sandbox container runs in rootless Podman
  ]);

  # NOTE: ROCm OpenCL for hashcat GPU is configured in amd-optimizations.nix
}
