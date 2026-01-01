# Security tools aliases and documentation
# NOTE: All packages are installed in modules/system/security-tools.nix
{ pkgs, ... }:

{
  # Create helpful aliases for common security tasks
  programs.zsh.shellAliases = {
    # Nmap shortcuts
    nmap-quick = "nmap -T4 -F";                          # Fast scan of common ports
    nmap-full = "nmap -T4 -A -v";                        # Aggressive scan with OS detection
    nmap-vuln = "nmap --script vuln";                    # Vulnerability scanning
    nmap-web = "nmap -p 80,443 --script http-enum";      # Web server enumeration

    # Wireshark/tcpdump
    tcpdump-http = "sudo tcpdump -A -s 0 'tcp port 80'"; # Capture HTTP traffic

    # Aircrack-ng shortcuts
    airmon-start = "sudo airmon-ng start wlan0";         # Start monitor mode
    airmon-stop = "sudo airmon-ng stop wlan0mon";        # Stop monitor mode

    # Wifite2 shortcuts (automated WiFi attacks)
    wifite-auto = "sudo wifite --kill";                  # Auto attack all WEP/WPA/WPS networks
    wifite-wpa = "sudo wifite --kill --wpa";             # Target only WPA networks
    wifite-wps = "sudo wifite --kill --wps";             # Target only WPS networks

    # hcxdumptool - PMKID attack (clientless)
    hcx-pmkid = "sudo hcxdumptool -i wlan0 -o capture.pcapng --enable_status=1"; # Capture PMKID
    hcx-convert = "hcxpcapngtool -o hash.22000";         # Convert to hashcat format

    # Hashcat with GPU
    hashcat-gpu = "hashcat -D 2";                        # Force GPU mode
    hashcat-bench = "hashcat -b";                        # Benchmark GPU performance
    hashcat-wifi = "hashcat -m 22000 -D 2 -w 3";         # WPA/WPA2 cracking with GPU
  };

  # Documentation and quick reference
  home.file.".config/security-tools/README.md".text = ''
    # Security Tools Quick Reference

    ## Installed Tools

    ### Network Scanning
    - **nmap**: Network scanner and security auditor
      ```bash
      nmap -sV -sC target.com              # Version detection + default scripts
      nmap -p- target.com                  # Scan all ports
      sudo nmap -sS target.com             # SYN stealth scan (requires root)
      ```

    ### Data Analysis & Crypto (CyberChef)

    **CyberChef** - The Cyber Swiss Army Knife (v10.19.4)
    Web-based tool for encryption, encoding, compression, and data analysis.

    ```bash
    # Launch CyberChef web interface
    cyberchef

    # Opens in your default browser at http://localhost:8000
    ```

    **Common Use Cases:**

    1. **Decode/Encode**:
       - Base64, Hex, URL encoding
       - ROT13, Caesar cipher
       - HTML entities, Unicode

    2. **Encryption/Decryption**:
       - AES, DES, 3DES, Blowfish
       - RSA operations
       - Hash functions (MD5, SHA, etc.)

    3. **Data Analysis**:
       - Extract strings from files
       - Parse JSON, XML
       - Analyze network packets
       - Extract URLs, emails, IPs

    4. **Forensics**:
       - File signature detection
       - Extract embedded files
       - Analyze malware samples

    5. **Chaining Operations**:
       - Combine multiple operations (recipes)
       - Save and share recipes
       - Auto-detect encodings

    **Example Workflows**:
    ```
    Base64 → Gunzip → From Hex → AES Decrypt
    Extract URLs → Filter by regex → Sort unique
    Reverse string → ROT13 → Base64 encode
    ```

    **Tips**:
    - Drag & drop operations to build recipes
    - Use "Magic" operation for auto-detection
    - Save recipes for reuse
    - Works offline (no data sent to server)

    ### Wireless Security (WiFi Hacking)

    #### Method 1: Wifite2 (AUTOMATED - Easiest)
    Wifite2 automates everything - best for beginners!

    ```bash
    # Auto-attack all networks (WEP/WPA/WPS)
    sudo wifite --kill

    # Target only WPA/WPA2 networks
    sudo wifite --kill --wpa

    # Target only WPS-enabled routers
    sudo wifite --kill --wps

    # Use custom wordlist
    sudo wifite --kill --dict /path/to/wordlist.txt

    # Target specific network by ESSID
    sudo wifite --kill --essid "NetworkName"
    ```

    #### Method 2: PMKID Attack (NO CLIENTS NEEDED - Fastest)
    Modern attack that doesn't require waiting for clients!

    ```bash
    # 1. Capture PMKID (no handshake needed!)
    sudo hcxdumptool -i wlan0 -o capture.pcapng --enable_status=1

    # 2. Convert to hashcat format
    hcxpcapngtool -o hash.22000 capture.pcapng

    # 3. Crack with hashcat (GPU-accelerated)
    hashcat -m 22000 hash.22000 wordlist.txt -D 2 -w 3
    # -m 22000 : WPA-PBKDF2-PMKID+EAPOL
    # -D 2     : Use GPU only
    # -w 3     : High workload (max GPU usage)

    # Alternative: Use CPU + GPU
    hashcat -m 22000 hash.22000 wordlist.txt -w 3
    ```

    #### Method 3: Traditional Handshake Capture (Classic method)

    ```bash
    # 1. Enable monitor mode
    sudo airmon-ng start wlan0

    # 2. Scan networks
    sudo airodump-ng wlan0mon

    # 3. Capture specific network (replace XX with BSSID, 6 with channel)
    sudo airodump-ng -c 6 --bssid XX:XX:XX:XX:XX:XX -w capture wlan0mon

    # 4. In another terminal: Force client reconnection
    sudo aireplay-ng -0 10 -a XX:XX:XX:XX:XX:XX wlan0mon
    # -0 10 : Send 10 deauth packets

    # 5. Wait for "WPA handshake" message in airodump-ng

    # 6. Crack with aircrack-ng (CPU only, slow)
    aircrack-ng -w wordlist.txt capture-01.cap

    # OR convert to hashcat for GPU cracking (FASTER!)
    hcxpcapngtool -o hash.22000 capture-01.cap
    hashcat -m 22000 hash.22000 wordlist.txt -D 2 -w 3

    # 7. Stop monitor mode
    sudo airmon-ng stop wlan0mon
    ```

    #### Method 4: WPS Attack (PIN Bruteforce)

    ```bash
    # Reaver - WPS PIN attack
    sudo reaverwps -i wlan0mon -b XX:XX:XX:XX:XX:XX -vv

    # PixieWPS - PixieDust attack (faster if vulnerable)
    sudo reaverwps -i wlan0mon -b XX:XX:XX:XX:XX:XX -vv -K
    ```

    #### Method 5: Evil Twin / Fake AP Attack

    ```bash
    # 1. Create fake access point with hostapd
    # (Advanced - requires custom hostapd.conf file)

    # 2. Start DHCP server
    sudo dnsmasq -C /path/to/dnsmasq.conf

    # 3. Use bettercap for MITM
    sudo bettercap -iface wlan0
    ```

    #### Wireless Monitoring & Reconnaissance

    ```bash
    # Kismet - Advanced wireless monitoring
    sudo kismet

    # Bettercap - Modern framework
    sudo bettercap -iface wlan0
    ```

    #### WiFi DoS/Stress Testing

    ```bash
    # MDK4 - Deauth flood
    sudo mdk4 wlan0mon d -c 6

    # Continuous deauth attack
    sudo aireplay-ng -0 0 -a [BSSID] wlan0mon
    ```

    ### Web Application Testing
    - **sqlmap**: SQL injection testing
      ```bash
      sqlmap -u "http://target.com/page?id=1" --dbs  # Enumerate databases
      sqlmap -u "http://target.com/page?id=1" --dump # Dump data
      ```

    - **nikto**: Web server scanner
      ```bash
      nikto -h http://target.com           # Basic scan
      ```

    ### Password Cracking
    - **hashcat**: GPU-accelerated cracking (uses AMD Radeon 780M)
      ```bash
      hashcat -m 0 hashes.txt wordlist.txt # MD5 cracking
      hashcat -m 1000 hashes.txt wordlist.txt # NTLM cracking
      hashcat -m 1800 hashes.txt wordlist.txt # SHA-512 cracking
      hashcat -b                           # Benchmark your GPU
      ```

      Hash modes: -m 0 (MD5), -m 100 (SHA1), -m 1000 (NTLM), -m 1800 (SHA-512)

    - **john**: John the Ripper
      ```bash
      john --wordlist=wordlist.txt hashes.txt  # Dictionary attack
      john --show hashes.txt                   # Show cracked passwords
      ```

    ### Network Analysis
    - **wireshark**: Packet analyzer (GUI)
      ```bash
      wireshark                            # Launch GUI
      ```

    - **tcpdump**: Command-line packet capture
      ```bash
      sudo tcpdump -i any -w capture.pcap  # Capture all interfaces
      sudo tcpdump -r capture.pcap         # Read capture file
      ```

    ### SSL/TLS Testing
    - **testssl**: Comprehensive SSL/TLS testing
      ```bash
      testssl.sh https://target.com
      ```

    ## GPU Acceleration (AMD Radeon 780M)

    Your AMD Radeon 780M iGPU is configured with ROCm OpenCL for hashcat acceleration.

    Test GPU performance:
    ```bash
    hashcat -b -D 2  # Benchmark GPU only
    ```

    ## Security Notes

    ⚠️ **IMPORTANT**: Use these tools only for:
    - Authorized penetration testing engagements
    - Your own systems and networks
    - Educational purposes (CTF competitions, labs)
    - Security research with proper authorization

    Unauthorized use of these tools may be illegal and unethical.

    ## Useful Wordlists

    SecLists is installed and contains:
    - `/nix/store/.../share/seclists/` (find with: `find $(nix-build '<nixpkgs>' -A seclists --no-out-link)/share`)
    - Common passwords
    - Usernames
    - Web content discovery lists
    - Fuzzing payloads

    Common wordlist: `/usr/share/wordlists/rockyou.txt` (download separately if needed)

    ## Resources

    - Nmap: https://nmap.org/book/man.html
    - Aircrack-ng: https://www.aircrack-ng.org/doku.php
    - Hashcat: https://hashcat.net/wiki/
    - OWASP Testing Guide: https://owasp.org/www-project-web-security-testing-guide/
  '';
}
