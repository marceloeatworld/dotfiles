# Malware Analysis Lab - Multi-VM management
#
# 3 VMs profiles:
#   flare   -> FLARE-VM (Win10 + Mandiant install.ps1) - Windows malware analysis
#   remnux  -> REMnux (Ubuntu + remnux-cli) - network/cross-platform analysis, fake internet
#   devwin  -> Dev-Win (Tiny10/Win10) - legitimate dev/compile/test (NOT isolated)
#
# Networks:
#   lab-isolated  -> no internet, VMs can talk to each other (detonation chamber)
#   lab-nat       -> NAT for updates only (switched temporarily)
#   default       -> regular libvirt NAT (for dev-win only)
#
# Workflow:
#   1. analysis-vm setup                  # create networks (once)
#   2. analysis-vm install-remnux         # fetch + import REMnux OVA
#   3. analysis-vm install-flare          # show guide to install FLARE-VM
#   4. analysis-vm install-devwin         # show guide to install dev Windows
#   5. analysis-vm <vm> start             # start in isolated mode (flare/remnux)
#   6. analysis-vm <vm> network-on        # temporarily enable internet (updates)
#   7. analysis-vm <vm> snapshot clean
#   8. analysis-vm <vm> killswitch        # force isolation
#   9. Analyze malware; REMnux = fake internet for FLARE-VM
#   10. analysis-vm <vm> restore clean    # auto-killswitch

{ config, pkgs, ... }:

let
  labDir = "${config.home.homeDirectory}/lab";
  samplesDir = "${labDir}/samples";
  isosDir = "${labDir}/isos";

  analysis-vm = pkgs.writeShellScriptBin "analysis-vm" ''
    set -u

    VIRSH="${pkgs.libvirt}/bin/virsh --connect qemu:///system"
    VIRT_VIEWER="${pkgs.virt-viewer}/bin/virt-viewer --connect qemu:///system"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    QEMU_IMG="${pkgs.qemu}/bin/qemu-img"
    CURL="${pkgs.curl}/bin/curl"
    IP="${pkgs.iproute2}/bin/ip"
    IPTABLES="${pkgs.iptables}/bin/iptables"
    GREP="${pkgs.gnugrep}/bin/grep"
    AWK="${pkgs.gawk}/bin/awk"
    TAR="${pkgs.gnutar}/bin/tar"

    LAB_DIR="${labDir}"
    SAMPLES_DIR="${samplesDir}"
    ISOS_DIR="${isosDir}"

    ISOLATED_NET="lab-isolated"
    NAT_NET="lab-nat"

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'

    # ═══════════════════════════════════════════════════════════
    # VM profile resolution
    # ═══════════════════════════════════════════════════════════

    resolve_vm_name() {
      case "$1" in
        flare)  echo "FLARE-VM" ;;
        remnux) echo "REMnux" ;;
        devwin) echo "Dev-Win" ;;
        *)      echo "" ;;
      esac
    }

    is_isolated_vm() {
      # flare and remnux default to isolated; devwin never isolated
      case "$1" in
        flare|remnux) return 0 ;;
        *) return 1 ;;
      esac
    }

    check_vm_exists() {
      $VIRSH list --all --name 2>/dev/null | $GREP -q "^$1$"
    }

    get_vm_network() {
      $VIRSH domiflist "$1" 2>/dev/null | $GREP -E "network|bridge" | $AWK '{print $3}' | head -1
    }

    get_vm_mac() {
      $VIRSH domiflist "$1" 2>/dev/null | $GREP -E "network|bridge" | $AWK '{print $5}' | head -1
    }

    # ═══════════════════════════════════════════════════════════
    # Network setup (one-time)
    # ═══════════════════════════════════════════════════════════

    create_nwfilter() {
      if ! $VIRSH nwfilter-list | $GREP -q "lab-block-all"; then
        echo "Creating nwfilter 'lab-block-all'..."
        cat <<'FILTERXML' | $VIRSH nwfilter-define /dev/stdin
<filter name='lab-block-all' chain='root'>
  <uuid>d217f2e8-e8f5-4858-9c6a-9e5c6c6c6c6d</uuid>
  <rule action='drop' direction='out' priority='100'>
    <all/>
  </rule>
  <rule action='drop' direction='in' priority='100'>
    <all/>
  </rule>
  <!-- Allow DHCP (needed for VM to get IP from libvirt) -->
  <rule action='accept' direction='out' priority='50'>
    <udp srcportstart='68' dstportstart='67'/>
  </rule>
  <rule action='accept' direction='in' priority='50'>
    <udp srcportstart='67' dstportstart='68'/>
  </rule>
  <!-- Allow ARP (VMs need to find each other) -->
  <rule action='accept' direction='inout' priority='50'>
    <mac protocolid='arp'/>
  </rule>
  <!-- Allow inter-VM traffic on isolated subnet 192.168.100.0/24 -->
  <rule action='accept' direction='inout' priority='40'>
    <ip srcipaddr='192.168.100.0' srcipmask='255.255.255.0'
        dstipaddr='192.168.100.0' dstipmask='255.255.255.0'/>
  </rule>
</filter>
FILTERXML
      fi
    }

    create_networks() {
      create_nwfilter

      # Isolated: no forward, FLARE talks to REMnux only
      if ! $VIRSH net-info "$ISOLATED_NET" &>/dev/null; then
        echo "Creating isolated network..."
        cat <<'NETXML' | $VIRSH net-define /dev/stdin
<network>
  <name>lab-isolated</name>
  <bridge name="virbr-lab-iso"/>
  <ip address="192.168.100.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.100.10" end="192.168.100.50"/>
      <host mac="52:54:00:aa:bb:01" name="REMnux"   ip="192.168.100.2"/>
      <host mac="52:54:00:aa:bb:02" name="FLARE-VM" ip="192.168.100.10"/>
    </dhcp>
  </ip>
</network>
NETXML
        $VIRSH net-start "$ISOLATED_NET"
        $VIRSH net-autostart "$ISOLATED_NET"
      fi

      # NAT: temporary updates
      if ! $VIRSH net-info "$NAT_NET" &>/dev/null; then
        echo "Creating NAT network..."
        cat <<'NETXML' | $VIRSH net-define /dev/stdin
<network>
  <name>lab-nat</name>
  <forward mode="nat">
    <nat><port start="1024" end="65535"/></nat>
  </forward>
  <bridge name="virbr-lab-nat"/>
  <ip address="192.168.101.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.101.10" end="192.168.101.50"/>
    </dhcp>
  </ip>
</network>
NETXML
        $VIRSH net-start "$NAT_NET"
        $VIRSH net-autostart "$NAT_NET"
      fi

      # Ensure default network exists and is started (for dev-win)
      if ! $VIRSH net-info default &>/dev/null 2>&1; then
        echo "Warning: default libvirt network missing. dev-win needs it for internet."
      else
        $VIRSH net-start default 2>/dev/null || true
        $VIRSH net-autostart default 2>/dev/null || true
      fi

      echo -e "''${GREEN}✅ Networks and nwfilter ready''${NC}"
    }

    # ═══════════════════════════════════════════════════════════
    # VM control
    # ═══════════════════════════════════════════════════════════

    switch_network() {
      local VM="$1" TARGET_NET="$2"
      local MAC STATE
      MAC=$(get_vm_mac "$VM")
      if [ -z "$MAC" ]; then
        echo -e "''${RED}Error: could not get MAC for $VM''${NC}"
        return 1
      fi
      STATE=$($VIRSH domstate "$VM" 2>/dev/null || echo "unknown")
      if [ "$STATE" = "running" ]; then
        $VIRSH detach-interface "$VM" network --mac "$MAC" --live --config 2>/dev/null \
          || $VIRSH detach-interface "$VM" network --mac "$MAC" --live 2>/dev/null \
          || true
        $VIRSH attach-interface "$VM" network "$TARGET_NET" --mac "$MAC" --model virtio --live --config \
          || $VIRSH attach-interface "$VM" network "$TARGET_NET" --mac "$MAC" --model virtio --live
      else
        $VIRSH detach-interface "$VM" network --mac "$MAC" --config 2>/dev/null || true
        $VIRSH attach-interface "$VM" network "$TARGET_NET" --mac "$MAC" --model virtio --config
      fi
    }

    killswitch() {
      local VM="$1" PROFILE="$2"
      if ! check_vm_exists "$VM"; then
        echo -e "''${RED}VM '$VM' not found. Install first: analysis-vm install-$PROFILE''${NC}"
        return 1
      fi
      if ! is_isolated_vm "$PROFILE"; then
        echo -e "''${YELLOW}killswitch not applicable to $PROFILE (no isolation by design)''${NC}"
        return 0
      fi
      create_nwfilter
      switch_network "$VM" "$ISOLATED_NET"
      echo -e "''${GREEN}🔒 $VM isolated (lab-isolated)''${NC}"
      $NOTIFY "Analysis VM" "🔒 $VM killswitch active"
    }

    network_on() {
      local VM="$1" PROFILE="$2"
      if ! check_vm_exists "$VM"; then
        echo -e "''${RED}VM '$VM' not found''${NC}"
        return 1
      fi
      if ! is_isolated_vm "$PROFILE"; then
        echo -e "''${YELLOW}$PROFILE already uses regular NAT, nothing to do.''${NC}"
        return 0
      fi
      echo -e "''${YELLOW}⚠️  WARNING: enabling internet for $VM''${NC}"
      read -p "Confirm (yes/no): " CONFIRM
      [ "$CONFIRM" = "yes" ] || { echo "Cancelled"; return 0; }
      switch_network "$VM" "$NAT_NET"
      echo -e "''${GREEN}✅ $VM on NAT''${NC}"
      echo -e "''${YELLOW}⚠️  Run 'analysis-vm $PROFILE killswitch' BEFORE analysis!''${NC}"
      $NOTIFY -u critical "Analysis VM" "⚠️ $VM NAT enabled"
    }

    start_vm() {
      local VM="$1" PROFILE="$2"
      if ! check_vm_exists "$VM"; then
        echo -e "''${RED}VM '$VM' not found. Run: analysis-vm install-$PROFILE''${NC}"
        return 1
      fi
      $VIRSH start "$VM" 2>/dev/null || true
      sleep 2
      if is_isolated_vm "$PROFILE"; then
        killswitch "$VM" "$PROFILE"
      fi
      echo "Opening viewer..."
      $VIRT_VIEWER "$VM" &
    }

    stop_vm() {
      local VM="$1"
      if ! check_vm_exists "$VM"; then return 1; fi
      $VIRSH shutdown "$VM" 2>/dev/null || true
      echo "Shutdown signal sent to $VM."
    }

    # ═══════════════════════════════════════════════════════════
    # Snapshots
    # ═══════════════════════════════════════════════════════════

    snapshot_create() {
      local VM="$1" NAME="''${2:-clean-$(date +%Y%m%d-%H%M%S)}"
      check_vm_exists "$VM" || { echo -e "''${RED}$VM not found''${NC}"; return 1; }
      $VIRSH snapshot-create-as "$VM" --name "$NAME" --description "Analysis snapshot"
      echo -e "''${GREEN}✅ Snapshot '$NAME' on $VM''${NC}"
    }

    snapshot_restore() {
      local VM="$1" NAME="''${2:-}" PROFILE="$3"
      check_vm_exists "$VM" || return 1
      if [ -z "$NAME" ]; then
        echo "Available snapshots:"
        $VIRSH snapshot-list "$VM" --name
        read -p "Snapshot name: " NAME
      fi
      [ -z "$NAME" ] && { echo "No name"; return 1; }
      $VIRSH snapshot-revert "$VM" --snapshotname "$NAME"
      echo -e "''${GREEN}✅ $VM restored to '$NAME'""''${NC}"
      is_isolated_vm "$PROFILE" && killswitch "$VM" "$PROFILE"
    }

    snapshot_list() {
      local VM="$1"
      check_vm_exists "$VM" || return 1
      $VIRSH snapshot-list "$VM" --tree
    }

    # ═══════════════════════════════════════════════════════════
    # Status / verify
    # ═══════════════════════════════════════════════════════════

    status() {
      local VM="$1" PROFILE="$2"
      if ! check_vm_exists "$VM"; then
        echo -e "''${YELLOW}$VM not installed. Run: analysis-vm install-$PROFILE''${NC}"
        return 0
      fi
      local STATE NET
      STATE=$($VIRSH domstate "$VM" 2>/dev/null)
      NET=$(get_vm_network "$VM")

      echo ""
      echo -e "''${BOLD}=== $VM ===''${NC}"
      echo "  State:   $STATE"
      case "$NET" in
        "$ISOLATED_NET") echo -e "  Network: ''${GREEN}🔒 isolated''${NC}" ;;
        "$NAT_NET")      echo -e "  Network: ''${RED}⚠️  lab-nat (internet)''${NC}" ;;
        default)         echo -e "  Network: ''${BLUE}default (regular NAT)''${NC}" ;;
        *)               echo "  Network: $NET" ;;
      esac
      echo "  Snapshots:"
      $VIRSH snapshot-list "$VM" --name 2>/dev/null | while read s; do
        [ -n "$s" ] && echo "    - $s"
      done
    }

    verify() {
      local VM="$1" PROFILE="$2"
      if ! is_isolated_vm "$PROFILE"; then
        echo "verify only applies to flare/remnux (isolated VMs)"
        return 0
      fi
      local NET
      NET=$(get_vm_network "$VM")
      echo ""
      echo -e "''${BOLD}Isolation check for $VM:''${NC}"
      if [ "$NET" = "$ISOLATED_NET" ]; then
        echo -e "  ✓ On isolated network: ''${GREEN}OK''${NC}"
      else
        echo -e "  ✗ On $NET: ''${RED}NOT ISOLATED''${NC}"
      fi
      if $VIRSH net-dumpxml "$ISOLATED_NET" 2>/dev/null | $GREP -q "<forward"; then
        echo -e "  ✗ Forward present: ''${RED}DANGEROUS''${NC}"
      else
        echo -e "  ✓ No forward: ''${GREEN}OK''${NC}"
      fi
      echo "  iptables FORWARD rules for virbr-lab-iso:"
      $IPTABLES -L FORWARD -n 2>/dev/null | $GREP -E "virbr-lab-iso" | head -5 || echo "    (none found - expected on isolated net)"
    }

    # ═══════════════════════════════════════════════════════════
    # Install helpers
    # ═══════════════════════════════════════════════════════════

    install_remnux() {
      mkdir -p "$ISOS_DIR"
      cd "$ISOS_DIR"

      echo -e "''${BOLD}REMnux install''${NC}"
      echo ""
      echo "Two options:"
      echo "  1. OVA (pre-built, ~3GB download)"
      echo "  2. On-top-of-Ubuntu (install fresh Ubuntu 22.04 first, then run remnux-cli)"
      echo ""
      read -p "Choose [1/2]: " CHOICE

      case "$CHOICE" in
        1)
          echo ""
          echo "Official REMnux OVA download page:"
          echo "  https://docs.remnux.org/install-distro/install-from-virtual-appliance"
          echo ""
          echo "After downloading the .ova file:"
          echo "  1. Place it in: $ISOS_DIR/"
          echo "  2. Extract:     tar -xvf $ISOS_DIR/remnux-*.ova -C $ISOS_DIR/"
          echo "  3. Convert:     qemu-img convert -f vmdk -O qcow2 $ISOS_DIR/remnux-*.vmdk /var/lib/libvirt/images/REMnux.qcow2"
          echo "  4. Import in virt-manager:"
          echo "     - File → New VM → Import existing disk image"
          echo "     - Storage: /var/lib/libvirt/images/REMnux.qcow2"
          echo "     - OS: Ubuntu 20.04"
          echo "     - Memory: 4096 MB, CPUs: 2"
          echo "     - Name: REMnux"
          echo "     - Network: lab-isolated"
          echo "     - MAC: 52:54:00:aa:bb:01  (static DHCP assignment → 192.168.100.2)"
          ;;
        2)
          cat <<INSTRUCTIONS

Install Ubuntu 22.04 Desktop/Server in a new VM named "REMnux":
  1. Download Ubuntu 22.04 ISO: https://ubuntu.com/download/desktop
  2. In virt-manager: create VM, 40GB disk, 4GB RAM, 2 vCPU
  3. Network: lab-nat (needs internet to install REMnux tools)
  4. MAC: 52:54:00:aa:bb:01
  5. Install Ubuntu normally
  6. After first boot, inside the VM run:

    wget https://REMnux.org/remnux-cli -O remnux && chmod +x remnux && sudo mv remnux /usr/local/bin/
    sudo remnux install

  7. Reboot, then:
    analysis-vm remnux snapshot clean
    analysis-vm remnux killswitch

REMnux ready. From now on it gets IP 192.168.100.2 on lab-isolated.
INSTRUCTIONS
          ;;
      esac

      echo ""
      echo "Once REMnux is running, configure INetSim inside it:"
      echo "  sudo nano /etc/inetsim/inetsim.conf   # set service_bind_address 192.168.100.2"
      echo "  sudo systemctl enable --now inetsim"
      echo ""
      echo "Then FLARE-VM should use 192.168.100.2 as DNS and default gateway for fake internet."
    }

    install_flare() {
      cat <<'GUIDE'

FLARE-VM install guide
═══════════════════════════════════════════════════════════

PREREQ: a Windows 10 VM (LTSC recommended, or Tiny10 for smaller footprint).

1. Download Windows 10 ISO:
   - LTSC 2021: https://massgrave.dev/genuine-installation-media (eval, needs key to activate)
   - Tiny10   : https://archive.org/details/tiny-10-x-64-23-h-2 (unofficial, no license)

2. Create VM in virt-manager:
   - Name:    FLARE-VM
   - RAM:     6144 MB
   - CPUs:    4
   - Disk:    80 GB (qcow2)
   - Network: lab-nat  (need internet for FLARE install)
   - MAC:     52:54:00:aa:bb:02  (static → 192.168.100.10 on lab-isolated)
   - Firmware: UEFI (OVMF)
   - TPM:     2.0 (swtpm)
   - Attach virtio-win ISO for disk/network drivers during install

3. Install Windows 10 normally.

4. Inside Windows, BEFORE running FLARE-VM install:
   a. Settings → Update & Security → Windows Security → Virus & threat protection
      → Manage settings → Turn OFF: Real-time protection, Tamper protection, Cloud-delivered
   b. Disable Windows Update (services.msc → Windows Update → Disabled)
   c. Disable Windows Defender via Group Policy:
      gpedit.msc → Computer Config → Admin Templates → Windows Components → Microsoft Defender Antivirus
      → "Turn off Microsoft Defender Antivirus" = Enabled
   d. Reboot

5. Install FLARE-VM (as Administrator PowerShell):
   Set-ExecutionPolicy Unrestricted -Force
   (New-Object net.webclient).DownloadString('https://raw.githubusercontent.com/mandiant/flare-vm/main/install.ps1') | iex
   # Will prompt for user config; defaults are fine
   # Full install: 4-8 hours, 5-10 reboots (auto-resumes)

6. After install completes on host:
   analysis-vm flare snapshot clean-flare
   analysis-vm flare killswitch

7. Inside FLARE-VM, to use REMnux as fake internet:
   - Network adapter → Properties → IPv4:
     IP:       192.168.100.10
     Mask:     255.255.255.0
     Gateway:  192.168.100.2   (REMnux)
     DNS:      192.168.100.2

Tools included after FLARE install: IDA Free, x64dbg, PE Studio, Ghidra,
Detect-it-Easy, FLOSS, CAPA, Cutter, dnSpyEx, Fiddler, OllyDbg, ApateDNS,
FakeNet-NG, Process Hacker, Procmon, Procexp, Regshot, and ~100 more.

GUIDE
    }

    install_devwin() {
      cat <<'GUIDE'

Dev-Win install guide (legitimate dev/compile/test VM)
═══════════════════════════════════════════════════════════

This VM is NOT isolated. It uses regular libvirt NAT for normal internet.
Use it for: compiling software, testing EXEs you wrote, running dev tools
on Windows (.NET, Visual Studio, etc.). Never run untrusted binaries here.

1. Download Windows ISO:
   - Tiny10:  https://archive.org/details/tiny-10-x-64-23-h-2      (no license, ~4GB)
   - Tiny11:  https://archive.org/details/tiny-11-nt-core          (no license, ~4GB)
   - Win10:   https://www.microsoft.com/software-download/windows10
   - Win11:   https://www.microsoft.com/software-download/windows11

2. Create VM in virt-manager:
   - Name:    Dev-Win
   - RAM:     4096 MB
   - CPUs:    2
   - Disk:    40 GB (qcow2)
   - Network: default     (regular NAT, NOT lab-*)
   - Firmware: UEFI (OVMF)
   - TPM:     2.0 (required for Win11; optional for Win10)

3. Install Windows normally.

4. Install virtio-win drivers for better perf:
   - In VM: D:\virtio-win-gt-x64.msi  (from virtio-win ISO)

5. Optional: install dev tools you need (Visual Studio, .NET SDK, etc.)

6. Snapshot clean state:
   analysis-vm devwin snapshot clean-dev

GUIDE
    }

    # ═══════════════════════════════════════════════════════════
    # Help
    # ═══════════════════════════════════════════════════════════

    usage() {
      cat <<EOF
Analysis Lab - Multi-VM management for malware analysis and dev

Usage:
  analysis-vm setup                 Create lab networks + nwfilter (run once)

  analysis-vm install-remnux        Guide + partial automation for REMnux install
  analysis-vm install-flare         Guide for FLARE-VM install
  analysis-vm install-devwin        Guide for dev Windows install

  analysis-vm <vm> <command>

VMs:
  flare    FLARE-VM (Windows + Mandiant tools, isolated)
  remnux   REMnux (Ubuntu, isolated, acts as fake-internet for FLARE)
  devwin   Dev-Win (Windows for legit compile/test, regular NAT)

Commands:
  start                 Start VM (auto-killswitch for flare/remnux)
  stop                  Graceful shutdown
  killswitch            Force isolation (flare/remnux only)
  network-on            Temporary NAT for updates (flare/remnux only)
  snapshot [name]       Create snapshot
  restore [name]        Restore snapshot + auto-killswitch if isolated VM
  snapshots             List snapshots tree
  status                VM state + network
  verify                Check isolation (flare/remnux)

Paths:
  ~/lab/samples/        Malware samples (VirtioFS shared into VMs)
  ~/lab/isos/           Windows/Ubuntu ISOs you download

Security model:
  lab-isolated   no <forward>, nwfilter 'lab-block-all' blocks all except
                 DHCP/ARP and inter-VM traffic on 192.168.100.0/24
                 → FLARE can talk to REMnux (fake internet) but not to LAN/WAN
  lab-nat        NAT forward, used temporarily for updates only
  default        regular libvirt NAT (dev-win only)
EOF
    }

    # ═══════════════════════════════════════════════════════════
    # Dispatcher
    # ═══════════════════════════════════════════════════════════

    VM_ARG="''${1:-}"

    case "$VM_ARG" in
      setup)           create_networks; exit 0 ;;
      install-remnux)  install_remnux; exit 0 ;;
      install-flare)   install_flare; exit 0 ;;
      install-devwin)  install_devwin; exit 0 ;;
      ""|help|-h|--help) usage; exit 0 ;;
    esac

    LIBVIRT_VM=$(resolve_vm_name "$VM_ARG")
    if [ -z "$LIBVIRT_VM" ]; then
      echo -e "''${RED}Unknown VM: $VM_ARG''${NC}"
      usage
      exit 1
    fi

    CMD="''${2:-status}"

    case "$CMD" in
      start)                     start_vm "$LIBVIRT_VM" "$VM_ARG" ;;
      stop)                      stop_vm "$LIBVIRT_VM" ;;
      kill|killswitch|off)       killswitch "$LIBVIRT_VM" "$VM_ARG" ;;
      network-on|on|net)         network_on "$LIBVIRT_VM" "$VM_ARG" ;;
      snapshot|snap)             snapshot_create "$LIBVIRT_VM" "''${3:-}" ;;
      restore|revert)            snapshot_restore "$LIBVIRT_VM" "''${3:-}" "$VM_ARG" ;;
      snapshots|list)            snapshot_list "$LIBVIRT_VM" ;;
      status|s)                  status "$LIBVIRT_VM" "$VM_ARG" ;;
      verify)                    verify "$LIBVIRT_VM" "$VM_ARG" ;;
      *) echo -e "''${RED}Unknown command: $CMD''${NC}"; usage; exit 1 ;;
    esac
  '';

  # Backward-compat: malware-vm forwards to analysis-vm flare
  malware-vm-compat = pkgs.writeShellScriptBin "malware-vm" ''
    exec ${analysis-vm}/bin/analysis-vm flare "$@"
  '';

  # Lab menu: wofi-based quick actions (bound to SUPER+X in hyprland.nix)
  lab-menu = pkgs.writeShellScriptBin "lab-menu" ''
    VIRSH="${pkgs.libvirt}/bin/virsh --connect qemu:///system"
    VIEWER="${pkgs.virt-viewer}/bin/virt-viewer --connect qemu:///system"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    ANALYSIS_VM="${analysis-vm}/bin/analysis-vm"

    # Build status indicators for menu entries
    flare_state=$($VIRSH domstate FLARE-VM 2>/dev/null || echo "not found")
    remnux_state=$($VIRSH domstate REMnux 2>/dev/null || echo "not found")
    flare_icon=$([ "$flare_state" = "running" ] && echo "🟢" || echo "⚪")
    remnux_icon=$([ "$remnux_state" = "running" ] && echo "🟢" || echo "⚪")

    # Menu entries (emoji icons, readable labels)
    MENU="$flare_icon Start FLARE-VM ($flare_state)
$remnux_icon Start REMnux ($remnux_state)
🚀 Start both (REMnux → FLARE)
👁  Open FLARE-VM viewer
👁  Open REMnux viewer
🔁 Revert FLARE-VM → analysis-ready
🔁 Revert REMnux → analysis-ready
⏹  Shutdown FLARE-VM
⏹  Shutdown REMnux
⏹  Shutdown both
🔒 Killswitch FLARE-VM (force isolate)
🔒 Killswitch REMnux (force isolate)
📊 Lab status (notification)
📸 New snapshot FLARE-VM
📸 New snapshot REMnux"

    CHOICE=$(echo "$MENU" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Malware Lab" --width 500 --height 450)

    case "$CHOICE" in
      *"Start FLARE-VM"*)
        $ANALYSIS_VM flare start &
        $NOTIFY "Lab" "FLARE-VM starting with isolation enforced"
        ;;
      *"Start REMnux"*)
        $ANALYSIS_VM remnux start &
        $NOTIFY "Lab" "REMnux starting with isolation enforced"
        ;;
      *"Start both"*)
        (
          $ANALYSIS_VM remnux start
          sleep 3
          $ANALYSIS_VM flare start
        ) &
        $NOTIFY "Lab" "Both VMs starting with isolation enforced"
        ;;
      *"Open FLARE-VM viewer"*) $VIEWER FLARE-VM & ;;
      *"Open REMnux viewer"*)   $VIEWER REMnux & ;;
      *"Revert FLARE-VM"*)
        $VIRSH destroy FLARE-VM 2>/dev/null
        sleep 1
        if $ANALYSIS_VM flare restore analysis-ready 2>/dev/null; then
          $NOTIFY "Lab" "FLARE-VM reverted and isolated"
        else
          $NOTIFY -u critical "Lab" "Revert failed"
        fi
        ;;
      *"Revert REMnux"*)
        $VIRSH destroy REMnux 2>/dev/null
        sleep 1
        if $ANALYSIS_VM remnux restore analysis-ready 2>/dev/null; then
          $NOTIFY "Lab" "REMnux reverted and isolated"
        else
          $NOTIFY -u critical "Lab" "Revert failed"
        fi
        ;;
      *"Shutdown FLARE-VM"*) $VIRSH shutdown FLARE-VM && $NOTIFY "Lab" "FLARE-VM shutdown signal sent" ;;
      *"Shutdown REMnux"*)   $VIRSH shutdown REMnux   && $NOTIFY "Lab" "REMnux shutdown signal sent" ;;
      *"Shutdown both"*)
        $VIRSH shutdown FLARE-VM 2>/dev/null
        $VIRSH shutdown REMnux 2>/dev/null
        $NOTIFY "Lab" "Both VMs shutting down"
        ;;
      *"Killswitch FLARE-VM"*)
        if $ANALYSIS_VM flare killswitch 2>/dev/null; then
          $NOTIFY -u critical "Lab" "FLARE-VM isolated"
        else
          $NOTIFY -u critical "Lab" "Killswitch failed"
        fi
        ;;
      *"Killswitch REMnux"*)
        if $ANALYSIS_VM remnux killswitch 2>/dev/null; then
          $NOTIFY -u critical "Lab" "REMnux isolated"
        else
          $NOTIFY -u critical "Lab" "Killswitch failed"
        fi
        ;;
      *"Lab status"*)
        STATUS=$($VIRSH list --all 2>/dev/null | head -10)
        $NOTIFY "Lab Status" "$STATUS"
        ;;
      *"New snapshot FLARE-VM"*)
        NAME="snapshot-$(date +%Y%m%d-%H%M%S)"
        $VIRSH snapshot-create-as FLARE-VM --name "$NAME" --disk-only --atomic 2>&1 | $NOTIFY "Lab"
        ;;
      *"New snapshot REMnux"*)
        NAME="snapshot-$(date +%Y%m%d-%H%M%S)"
        $VIRSH snapshot-create-as REMnux --name "$NAME" --disk-only --atomic 2>&1 | $NOTIFY "Lab"
        ;;
    esac
  '';
in
{
  home.packages = [
    analysis-vm
    malware-vm-compat
    lab-menu
    pkgs.virt-viewer
  ];

  # Create lab directory structure
  home.activation.labDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${samplesDir}" "${isosDir}"
    if [ ! -f "${labDir}/README.md" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/tee "${labDir}/README.md" > /dev/null <<'README'
# Malware Analysis Lab

## Directories
- `samples/` -> malware samples (share via VirtioFS into VMs, read-only)
- `isos/`    -> Windows/Ubuntu ISOs for VM installs

## VMs
- `analysis-vm flare   start` -> FLARE-VM (Windows malware analysis)
- `analysis-vm remnux  start` -> REMnux (fake internet, Linux analysis)
- `analysis-vm devwin  start` -> Dev-Win (legit dev, regular NAT)

## Samples sharing (VirtioFS)
Add to VM XML (via virt-manager → Add Hardware → Filesystem):
  Driver:       virtiofs
  Source path:  /home/marcelo/lab/samples
  Target path:  samples
  Mode:         mapped

Inside guest:
  Windows:    needs WinFsp + virtiofs drivers from virtio-win
              mount: `net use S: \\virtiofs.samples`
  Linux:      `mount -t virtiofs samples /mnt/samples`

Always mount read-only to avoid sample cross-contamination.
README
    fi
  '';
}
