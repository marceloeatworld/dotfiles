# 🚀 INSTALLATION GUIDE - ThinkPad P14s Gen 5

Complete NixOS 25.05 installation with Hyprland on ThinkPad P14s Gen 5 (AMD).

---

## 📋 **PREREQUISITES**

- ✅ USB drive (minimum 4GB)
- ✅ ThinkPad P14s Gen 5 (AMD)
- ✅ Internet connection (WiFi or Ethernet)
- ✅ Backup your data (disk will be wiped!)

---

## 🔥 **STEP 1: CREATE BOOTABLE USB**

### **On Linux/WSL:**

```bash
# Download NixOS 25.05 ISO (Graphical)
wget https://channels.nixos.org/nixos-25.05/latest-nixos-gnome-x86_64-linux.iso

# Identify your USB drive
lsblk

# Write ISO (replace sdX with your USB drive, e.g., sdb)
sudo dd if=latest-nixos-gnome-x86_64-linux.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

### **On Windows:**

1. Download: https://channels.nixos.org/nixos-25.05/latest-nixos-gnome-x86_64-linux.iso
2. Use **Rufus** or **Balena Etcher**
3. Select ISO and USB drive
4. Write in DD mode

---

## 💻 **STEP 2: BOOT FROM USB**

1. **Insert USB drive** into ThinkPad
2. **Reboot** and press **F12** (Boot Menu)
3. **Select** USB drive
4. **Wait** for Live USB to boot

---

## 🌐 **STEP 3: INTERNET CONNECTION**

### **WiFi:**

```bash
# Graphical interface (easier)
nmtui

# Or command line
sudo systemctl start wpa_supplicant
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Test connection
ping -c 3 nixos.org
```

---

## 📦 **STEP 4: CLONE YOUR CONFIGURATION**

```bash
# Switch to root
sudo su

# Install Git (if not present)
nix-shell -p git

# Clone your dotfiles repo
cd /mnt
git clone https://github.com/YOUR_USERNAME/dotfiles thinkpad-p14s-gen5
cd thinkpad-p14s-gen5
```

---

## 💾 **STEP 5: VERIFY DISK CONFIGURATION**

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

## 🔧 **STEP 6: DISKO - AUTOMATIC PARTITIONING**

**⚠️ WARNING: This command WIPES THE ENTIRE DISK!**

```bash
# Install disko in shell
nix --extra-experimental-features 'nix-command flakes' \
    run github:nix-community/disko -- \
    --mode disko \
    hosts/thinkpad/disko-config.nix

# Disko will:
# 1. Create EFI partition (512MB)
# 2. Create encrypted LUKS partition (rest)
# 3. Format with Btrfs
# 4. Create 7 subvolumes
# 5. Mount everything under /mnt

# You will need to enter:
# - LUKS encryption password (⚠️ DO NOT FORGET!)
```

---

## 📝 **STEP 7: VERIFY MOUNTS**

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

## 🎯 **STEP 8: GENERATE hardware-configuration.nix**

```bash
# Generate hardware config
nixos-generate-config --root /mnt

# Copy hardware-configuration.nix to your config
cp /mnt/etc/nixos/hardware-configuration.nix \
   hosts/thinkpad/hardware-configuration.nix

# IMPORTANT: Verify file contains:
# - boot.initrd.luks.devices."crypted"
# - All Btrfs mount options

cat hosts/thinkpad/hardware-configuration.nix
```

---

## 🚀 **STEP 9: INSTALLATION**

```bash
# Copy config to /mnt
cp -r /mnt/thinkpad-p14s-gen5 /mnt/home/marcelo/dotfiles

# Install NixOS with your flake
nixos-install --flake /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5#pop

# ⏳ Installation takes 20-40 minutes
# NixOS will:
# - Download all packages
# - Compile what's necessary
# - Configure the system
# - Install Hyprland
# - Configure all modules
```

### **Set root password:**

```bash
# When prompted, set root password
# Or after installation:
nixos-enter
passwd root
passwd marcelo  # ⚠️ IMPORTANT: Set user password
exit
```

---

## 🔄 **STEP 10: REBOOT**

```bash
# Unmount and reboot
umount -R /mnt
reboot

# ⚠️ Remove USB drive during reboot
```

---

## 🎉 **FIRST BOOT**

### **1. LUKS Decryption:**
- Enter LUKS password
- System boots

### **2. TTY Login:**
```bash
# Login: marcelo
# Password: (set with passwd)
```

### **3. Launch Hyprland:**
```bash
# Hyprland should launch automatically
# If not:
uwsm start -S hyprland-uwsm.desktop
```

---

## ✅ **POST-INSTALLATION**

### **1. Verify system:**

```bash
# NixOS version
nixos-version
# → 25.05

# Graphical session
echo $XDG_SESSION_TYPE
# → wayland

# GPU
lspci | grep VGA
# → AMD Radeon 780M

# WiFi
nmcli device status
```

### **2. Update if necessary:**

```bash
# Navigate to config
cd ~/dotfiles/thinkpad-p14s-gen5

# Update flake
nix flake update

# Rebuild
sudo nixos-rebuild switch --flake .#pop
```

### **3. Configure Hyprland:**

```bash
# Test keybindings
SUPER + D           # Walker (launcher)
SUPER + Return      # Kitty (terminal)
SUPER + B           # Brave
SUPER + Q           # Close window
SUPER + Escape      # Lock screen
```

### **4. Launch web apps:**

```bash
# Walker → type "whatsapp", "spotify", "discord", "claude"
SUPER + D

# Or in terminal
gtk-launch whatsapp-web
gtk-launch spotify-web
gtk-launch discord-web
gtk-launch claude-web
gtk-launch protonmail-web
gtk-launch protondrive-web
```

### **5. Btrfs Snapshots:**

```bash
# List snapshots (automatic every 15min)
ls /.snapshots/home
ls /.snapshots/root

# Recover a file
cp /.snapshots/home/2024-10-24_12-00/marcelo/Documents/file.txt ~/
```

---

## 🔧 **TROUBLESHOOTING**

### **Problem: Installation fails**

```bash
# Check logs
journalctl -xe

# Verify Nix syntax
cd /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5
nix flake check
```

### **Problem: No network after installation**

```bash
# Enable NetworkManager
sudo systemctl start NetworkManager
sudo systemctl enable NetworkManager

# Connect WiFi
nmtui
```

### **Problem: Hyprland won't start**

```bash
# Check logs
journalctl --user -u hyprland

# Launch manually
uwsm start -S hyprland-uwsm.desktop
```

### **Problem: LUKS password forgotten**

❌ **Cannot recover** - Disk data is lost
✅ **Solution:** Reinstall (that's why we make backups!)

---

## 📊 **QUICK SUMMARY**

```bash
# 1. Create USB
dd if=nixos.iso of=/dev/sdX bs=4M

# 2. Boot USB + Connect WiFi
nmtui

# 3. Clone
sudo su
git clone https://github.com/USER/dotfiles /mnt/thinkpad-p14s-gen5
cd /mnt/thinkpad-p14s-gen5

# 4. Disko (⚠️ WIPES DISK)
nix run github:nix-community/disko -- --mode disko hosts/thinkpad/disko-config.nix

# 5. Hardware config
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/thinkpad/

# 6. Install
cp -r . /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5
nixos-install --flake /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5#pop

# 7. Password
nixos-enter
passwd marcelo
exit

# 8. Reboot
reboot
```

---

## 🎯 **CHECKLIST**

- [ ] USB drive created
- [ ] Data backup done
- [ ] Boot from USB
- [ ] WiFi connected
- [ ] Repo cloned
- [ ] Disk device verified (nvme0n1)
- [ ] Disko executed
- [ ] LUKS password set (⚠️ written down somewhere)
- [ ] hardware-configuration.nix copied
- [ ] Installation launched
- [ ] marcelo password set
- [ ] Reboot successful
- [ ] Hyprland starts
- [ ] Web apps working

---

**Happy installation! 🚀**

*Simple, efficient, no frills.* ✨
