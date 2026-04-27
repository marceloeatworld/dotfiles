# INSTALLATION GUIDE - ThinkPad P14s Gen 5

Complete NixOS **unstable** minimal installation with Hyprland on ThinkPad P14s Gen 5 (AMD).

---

## PREREQUISITES

- USB drive (minimum 2GB)
- ThinkPad P14s Gen 5 (AMD)
- Internet connection (WiFi or Ethernet)
- Backup your data (disk will be wiped!)

---

## STEP 1: CREATE BOOTABLE USB

### On Linux/WSL:

```bash
# Download NixOS unstable ISO (MINIMAL - no GUI, smaller download)
wget https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso

# Identify your USB drive (find your USB, usually sdb or sdc)
lsblk

# Write ISO to USB (replace sdX with your USB drive)
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress && sync
```

### On Windows:

1. Download: https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso
2. Use **Rufus** or **Balena Etcher**
3. Select ISO and USB drive
4. Write in DD mode

---

## STEP 2: BOOT FROM USB

1. **Insert USB drive** into ThinkPad
2. **Reboot** and press **F12** (Boot Menu)
3. **Select** USB drive
4. **Wait** for Live USB to boot

---

## STEP 3: INTERNET CONNECTION

### WiFi (command line):

```bash
# Start wpa_supplicant
sudo systemctl start wpa_supplicant

# Connect to WiFi (ONE LINE - replace SSID and PASSWORD)
sudo wpa_passphrase "YOUR_SSID" "YOUR_PASSWORD" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf && sudo systemctl restart wpa_supplicant && sleep 5 && ping -c 3 nixos.org
```

### Alternative: If available, use nmcli:

```bash
# Connect to WiFi (ONE LINE)
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD" && ping -c 3 nixos.org
```

---

## STEP 4: CLONE YOUR CONFIGURATION

```bash
# Switch to root, install git, clone the repo, then enter the flake directory
sudo su
nix-shell -p git
cd /tmp
git clone https://github.com/marceloeatworld/dotfiles dotfiles
cd dotfiles/thinkpad-p14s-gen5

# Or step by step:
sudo su
nix-shell -p git
cd /tmp
git clone https://github.com/marceloeatworld/dotfiles dotfiles
cd dotfiles/thinkpad-p14s-gen5
```

---

## STEP 5: VERIFY DISK CONFIGURATION

**IMPORTANT:** Verify your SSD name!

```bash
# List disks
lsblk

# Your SSD should be:
# nvme0n1 (1TB NVMe SSD)
```

**Edit if necessary:**

```bash
# If your SSD is NOT nvme0n1, modify:
nano hosts/thinkpad/disko-config.nix

# Line 10: Change device = "/dev/nvme0n1";
# To correct device (e.g., /dev/nvme1n1 or /dev/sda)
```

---

## STEP 6: DISKO - AUTOMATIC PARTITIONING

**WARNING: This command WIPES THE ENTIRE DISK!**

```bash
# Run disko (ONE LINE - will prompt for LUKS password)
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko hosts/thinkpad/disko-config.nix

# Disko will:
# 1. Create EFI partition (512MB)
# 2. Create encrypted LUKS partition (rest)
# 3. Format with Btrfs
# 4. Create 7 subvolumes (@root, @home, @nix, @persist, @log, @snapshots, @swap)
# 5. Mount everything under /mnt

# You will be prompted to enter:
# - LUKS encryption password (REMEMBER THIS - no recovery possible!)
```

---

## STEP 7: VERIFY MOUNTS

```bash
# Verify everything is mounted
mount | grep /mnt

# You should see:
# /dev/mapper/crypted on /mnt type btrfs (subvol=@root)
# /dev/mapper/crypted on /mnt/home type btrfs (subvol=@home)
# /dev/mapper/crypted on /mnt/nix type btrfs (subvol=@nix)
# etc.

# Check available space
df -h /mnt
```

---

## STEP 8: GENERATE hardware-configuration.nix

```bash
# Generate hardware config WITHOUT filesystems (disko handles that) - ONE LINE
sudo nixos-generate-config --no-filesystems --root /mnt && sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/thinkpad/hardware-configuration.nix

# Or step by step:
sudo nixos-generate-config --no-filesystems --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/thinkpad/hardware-configuration.nix

# IMPORTANT: --no-filesystems flag is REQUIRED
# Disko already manages fileSystems configuration
# hardware-configuration.nix should ONLY contain:
# - boot.initrd.availableKernelModules
# - boot.initrd.kernelModules
# - boot.kernelModules
# - boot.initrd.luks.devices."crypted" (LUKS config)
# - nixpkgs.hostPlatform

# Verify:
cat hosts/thinkpad/hardware-configuration.nix
```

---

## STEP 9: INSTALLATION

```bash
# Copy repo to /mnt and install (ONE LINE)
sudo mkdir -p /mnt/home/marcelo && sudo cp -a /tmp/dotfiles /mnt/home/marcelo/dotfiles && sudo nixos-install --flake /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5#pop

# Or step by step:
sudo mkdir -p /mnt/home/marcelo
sudo cp -a /tmp/dotfiles /mnt/home/marcelo/dotfiles
sudo nixos-install --flake /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5#pop

# Installation takes 20-40 minutes depending on internet speed
# NixOS will:
# - Download all packages (~3-5GB)
# - Build what's necessary
# - Configure the entire system
# - Install Hyprland + all modules
```

### Set user password and repo ownership (CRITICAL):

```bash
# Set password for user marcelo and make the copied repo user-owned
sudo nixos-enter --root /mnt -c 'passwd marcelo && chown -R marcelo:users /home/marcelo/dotfiles'

# Or step by step:
sudo nixos-enter --root /mnt
passwd marcelo
chown -R marcelo:users /home/marcelo/dotfiles
exit

# IMPORTANT: You MUST set this password or you won't be able to login!
```

---

## STEP 10: REBOOT

```bash
# Unmount all and reboot (ONE LINE)
sudo umount -R /mnt && sudo reboot

# Remove USB drive when system shuts down
```

---

## FIRST BOOT

### 1. LUKS Decryption:
- Enter LUKS password
- System boots

### 2. TTY Login:
```bash
# Login: marcelo
# Password: (set with passwd)
```

### 3. Launch Hyprland:
```bash
# Hyprland launches automatically via UWSM on TTY1 login
# If not:
uwsm start hyprland-uwsm.desktop
```

---

## POST-INSTALLATION

### 1. Verify system:

```bash
# NixOS version
nixos-version
# → 26.05.20260422.0726a0e or newer unstable snapshot

# Graphical session
echo $XDG_SESSION_TYPE
# → wayland

# GPU
lspci | grep VGA
# → AMD Radeon 780M

# Zram
swapon --show
# → /dev/zram0 with zstd, around 24GB on 32GB RAM

# WiFi
nmcli device status
```

### 2. Update if necessary:

```bash
# Navigate to config
cd ~/dotfiles/thinkpad-p14s-gen5

# Update flake inputs + overlays + rebuild (recommended)
update

# Or manually:
nix flake update
nh os switch .
```

### 3. Configure Hyprland:

```bash
# Test keybindings
SUPER + D           # Hyprlauncher (launcher)
SUPER + Return      # Ghostty (terminal)
SUPER + B           # Brave
SUPER + Q           # Close window
SUPER + Escape      # Lock screen
```

### 4. Launch web apps:

```bash
# Hyprlauncher -> type "whatsapp", "spotify", "discord", "claude"
SUPER + D

# Or in terminal
gtk-launch whatsapp-web
gtk-launch spotify-web
gtk-launch discord-web
gtk-launch claude-web
```

### 5. Btrfs Snapshots:

```bash
# List snapshots (automatic every 15min, retained 7 days)
ls /.snapshots/home
ls /.snapshots/root

# Recover a file
cp /.snapshots/home/<timestamp>/marcelo/Documents/file.txt ~/
```

---

## TROUBLESHOOTING

### Problem: Installation fails

```bash
# Check logs
journalctl -xe

# Verify Nix syntax
cd /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5
nix flake check
```

### Problem: No network after installation

```bash
# Enable NetworkManager
sudo systemctl start NetworkManager
sudo systemctl enable NetworkManager

# Connect WiFi
nmtui
```

### Problem: Hyprland won't start

```bash
# Check logs
journalctl --user -u hyprland

# Launch manually
uwsm start hyprland-uwsm.desktop
```

### Problem: LUKS password forgotten

**Cannot recover** - Disk data is lost. Reinstall (that's why we make backups!).

---

## QUICK SUMMARY - ONE-LINE COMMANDS

```bash
# 1. Create USB (replace sdX with your USB drive)
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress && sync

# 2. Boot USB + Connect WiFi (replace SSID and PASSWORD)
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD" && ping -c 3 nixos.org

# 3. Switch to root, install git, clone repo, enter the flake directory
sudo su
nix-shell -p git
cd /tmp && git clone https://github.com/marceloeatworld/dotfiles dotfiles && cd dotfiles/thinkpad-p14s-gen5

# 4. Verify disk (should be nvme0n1)
lsblk

# 5. Run Disko (WIPES ENTIRE DISK - will prompt for LUKS password)
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko hosts/thinkpad/disko-config.nix

# 6. Generate hardware config WITHOUT filesystems (disko manages them)
sudo nixos-generate-config --no-filesystems --root /mnt && sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/thinkpad/hardware-configuration.nix

# 7. Copy repo and install NixOS
sudo mkdir -p /mnt/home/marcelo && sudo cp -a /tmp/dotfiles /mnt/home/marcelo/dotfiles && sudo nixos-install --flake /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5#pop

# 8. Set user password and repo ownership (CRITICAL - run AFTER installation completes)
sudo nixos-enter --root /mnt -c 'passwd marcelo && chown -R marcelo:users /home/marcelo/dotfiles'

# 9. Reboot
sudo umount -R /mnt && sudo reboot
```

### ULTRA-COMPACT (Copy-Paste After Connecting WiFi):

```bash
# Run these commands in order (YOU MUST BE ROOT)
sudo su
nix-shell -p git
cd /tmp && git clone https://github.com/marceloeatworld/dotfiles dotfiles && cd dotfiles/thinkpad-p14s-gen5
lsblk
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko hosts/thinkpad/disko-config.nix
sudo nixos-generate-config --no-filesystems --root /mnt && sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/thinkpad/hardware-configuration.nix
sudo mkdir -p /mnt/home/marcelo && sudo cp -a /tmp/dotfiles /mnt/home/marcelo/dotfiles && sudo nixos-install --flake /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5#pop
sudo nixos-enter --root /mnt -c 'passwd marcelo && chown -R marcelo:users /home/marcelo/dotfiles'
sudo umount -R /mnt && sudo reboot
```

---

## CHECKLIST

- [ ] USB drive created (minimal ISO)
- [ ] Data backup done (disk will be wiped)
- [ ] Boot from USB (F12 on ThinkPad)
- [ ] WiFi connected (ping nixos.org works)
- [ ] Root shell (sudo su)
- [ ] Repo cloned to /tmp/dotfiles
- [ ] Disk device verified (lsblk -> nvme0n1)
- [ ] Disko executed (disk partitioned + encrypted)
- [ ] LUKS password set (WRITE IT DOWN - no recovery!)
- [ ] Mounts verified (mount | grep /mnt)
- [ ] hardware-configuration.nix generated WITH --no-filesystems
- [ ] hardware-configuration.nix copied to repo
- [ ] Repo copied to /mnt/home/marcelo/dotfiles
- [ ] Installation launched (nixos-install --flake)
- [ ] User password set and repo ownership fixed
- [ ] Unmount and reboot
- [ ] LUKS unlock works
- [ ] Login as marcelo works
- [ ] Hyprland auto-starts via UWSM
- [ ] Internet works
- [ ] GPU working (lspci | grep VGA)
