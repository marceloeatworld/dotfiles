# 🚀 GUIDE D'INSTALLATION - ThinkPad P14s Gen 5

Installation complète de NixOS 25.05 avec Hyprland sur ThinkPad P14s Gen 5 (AMD).

---

## 📋 **PRÉ-REQUIS**

- ✅ Clé USB (minimum 4GB)
- ✅ ThinkPad P14s Gen 5 (AMD)
- ✅ Connexion Internet (WiFi ou Ethernet)
- ✅ Sauvegarde de vos données (le disque sera effacé !)

---

## 🔥 **ÉTAPE 1: CRÉER LA CLÉ USB BOOTABLE**

### **Sur Linux/WSL:**

```bash
# Télécharger l'ISO NixOS 25.05 (Graphical)
wget https://channels.nixos.org/nixos-25.05/latest-nixos-gnome-x86_64-linux.iso

# Identifier votre clé USB
lsblk

# Écrire l'ISO (remplacez sdX par votre clé USB, ex: sdb)
sudo dd if=latest-nixos-gnome-x86_64-linux.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

### **Sur Windows:**

1. Télécharger: https://channels.nixos.org/nixos-25.05/latest-nixos-gnome-x86_64-linux.iso
2. Utiliser **Rufus** ou **Balena Etcher**
3. Sélectionner l'ISO et la clé USB
4. Écrire en mode DD

---

## 💻 **ÉTAPE 2: DÉMARRER SUR LA CLÉ USB**

1. **Insérer la clé USB** dans le ThinkPad
2. **Redémarrer** et appuyer sur **F12** (Boot Menu)
3. **Sélectionner** la clé USB
4. **Attendre** le démarrage du Live USB

---

## 🌐 **ÉTAPE 3: CONNEXION INTERNET**

### **WiFi:**

```bash
# Interface graphique (plus simple)
nmtui

# Ou en ligne de commande
sudo systemctl start wpa_supplicant
nmcli device wifi connect "VOTRE_SSID" password "VOTRE_MOT_DE_PASSE"

# Tester
ping -c 3 nixos.org
```

---

## 📦 **ÉTAPE 4: CLONER VOTRE CONFIGURATION**

```bash
# Passer en root
sudo su

# Installer Git (si pas déjà présent)
nix-shell -p git

# Cloner votre repo dotfiles
cd /mnt
git clone https://github.com/VOTRE_USERNAME/dotfiles thinkpad-p14s-gen5
cd thinkpad-p14s-gen5
```

---

## 💾 **ÉTAPE 5: VÉRIFIER LA CONFIGURATION DISQUE**

**IMPORTANT:** Vérifiez le nom de votre SSD !

```bash
# Lister les disques
lsblk

# Votre SSD devrait être:
# nvme0n1 (1TB NVMe SSD)
```

**Éditer si nécessaire:**

```bash
# Si votre SSD n'est PAS nvme0n1, modifier:
nano hosts/thinkpad/disko-config.nix

# Ligne 10: Changer device = "/dev/nvme0n1";
# Par le bon device (ex: /dev/nvme1n1 ou /dev/sda)
```

---

## 🔧 **ÉTAPE 6: DISKO - PARTITIONNEMENT AUTOMATIQUE**

**⚠️ ATTENTION: Cette commande EFFACE TOUT LE DISQUE !**

```bash
# Installer disko dans le shell
nix --extra-experimental-features 'nix-command flakes' \
    run github:nix-community/disko -- \
    --mode disko \
    hosts/thinkpad/disko-config.nix

# Disko va:
# 1. Créer la partition EFI (1GB)
# 2. Créer la partition LUKS chiffrée (reste)
# 3. Formater en Btrfs
# 4. Créer les 7 sous-volumes
# 5. Monter tout dans /mnt

# Vous devrez entrer:
# - Mot de passe de chiffrement LUKS (⚠️ NE PAS OUBLIER!)
```

---

## 📝 **ÉTAPE 7: VÉRIFIER LE MONTAGE**

```bash
# Vérifier que tout est monté
mount | grep /mnt

# Vous devriez voir:
# /dev/mapper/crypted on /mnt type btrfs (subvol=@root)
# /dev/mapper/crypted on /mnt/home type btrfs (subvol=@home)
# /dev/mapper/crypted on /mnt/nix type btrfs (subvol=@nix)
# etc.

# Vérifier l'espace
df -h /mnt
```

---

## 🎯 **ÉTAPE 8: GÉNÉRER hardware-configuration.nix**

```bash
# Générer la config hardware
nixos-generate-config --root /mnt

# Copier hardware-configuration.nix dans votre config
cp /mnt/etc/nixos/hardware-configuration.nix \
   hosts/thinkpad/hardware-configuration.nix

# IMPORTANT: Vérifier que le fichier contient:
# - boot.initrd.luks.devices."crypted"
# - Toutes les options de montage Btrfs

cat hosts/thinkpad/hardware-configuration.nix
```

---

## 🚀 **ÉTAPE 9: INSTALLATION**

```bash
# Copier votre config dans /mnt
cp -r /mnt/thinkpad-p14s-gen5 /mnt/home/marcelo/dotfiles

# Installer NixOS avec votre flake
nixos-install --flake /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5#pop

# ⏳ L'installation prend 20-40 minutes
# NixOS va:
# - Télécharger tous les paquets
# - Compiler ce qui est nécessaire
# - Configurer le système
# - Installer Hyprland
# - Configurer tous vos modules
```

### **Définir le mot de passe root:**

```bash
# Quand demandé, définir le mot de passe root
# Ou après installation:
nixos-enter
passwd root
passwd marcelo  # ⚠️ IMPORTANT: Définir le mot de passe utilisateur
exit
```

---

## 🔄 **ÉTAPE 10: REDÉMARRAGE**

```bash
# Démonter et redémarrer
umount -R /mnt
reboot

# ⚠️ Retirer la clé USB pendant le redémarrage
```

---

## 🎉 **PREMIER DÉMARRAGE**

### **1. Déchiffrement LUKS:**
- Entrer le mot de passe LUKS
- Le système démarre

### **2. Login TTY:**
```bash
# Login: marcelo
# Password: (celui défini avec passwd)
```

### **3. Lancement Hyprland:**
```bash
# Hyprland devrait se lancer automatiquement
# Sinon:
uwsm start -S hyprland-uwsm.desktop
```

---

## ✅ **POST-INSTALLATION**

### **1. Vérifier le système:**

```bash
# Version NixOS
nixos-version
# → 25.05

# Système graphique
echo $XDG_SESSION_TYPE
# → wayland

# GPU
lspci | grep VGA
# → AMD Radeon 780M

# WiFi
nmcli device status
```

### **2. Mettre à jour si nécessaire:**

```bash
# Aller dans votre config
cd ~/dotfiles/thinkpad-p14s-gen5

# Mettre à jour le flake
nix flake update

# Rebuild
sudo nixos-rebuild switch --flake .#pop
```

### **3. Configurer Hyprland:**

```bash
# Tester les raccourcis
SUPER + D           # Wofi (launcher)
SUPER + Return      # Kitty (terminal)
SUPER + B           # Brave
SUPER + Q           # Fermer fenêtre
SUPER + Escape      # Lock screen
```

### **4. Lancer les web apps:**

```bash
# Wofi → taper "whatsapp", "spotify", "discord", "claude"
SUPER + D

# Ou en terminal
gtk-launch whatsapp-web
gtk-launch spotify-web
gtk-launch discord-web
gtk-launch claude-web
```

### **5. Snapshots Btrfs:**

```bash
# Lister les snapshots (automatiques toutes les 15min)
ls /.snapshots/home
ls /.snapshots/root

# Récupérer un fichier
cp /.snapshots/home/2024-10-24_12-00/marcelo/Documents/fichier.txt ~/
```

---

## 🔧 **DÉPANNAGE**

### **Problème: Installation échoue**

```bash
# Vérifier les logs
journalctl -xe

# Vérifier la syntaxe Nix
cd /mnt/home/marcelo/dotfiles/thinkpad-p14s-gen5
nix flake check
```

### **Problème: Pas de réseau après installation**

```bash
# Activer NetworkManager
sudo systemctl start NetworkManager
sudo systemctl enable NetworkManager

# Connecter WiFi
nmtui
```

### **Problème: Hyprland ne démarre pas**

```bash
# Vérifier les logs
journalctl --user -u hyprland

# Lancer manuellement
uwsm start -S hyprland-uwsm.desktop
```

### **Problème: Mot de passe LUKS oublié**

❌ **Impossible de récupérer** - Le disque est perdu
✅ **Solution:** Réinstaller (c'est pour ça qu'on fait des sauvegardes !)

---

## 📊 **RÉSUMÉ RAPIDE**

```bash
# 1. Créer USB
dd if=nixos.iso of=/dev/sdX bs=4M

# 2. Boot USB + Connect WiFi
nmtui

# 3. Clone
sudo su
git clone https://github.com/USER/dotfiles /mnt/thinkpad-p14s-gen5
cd /mnt/thinkpad-p14s-gen5

# 4. Disko (⚠️ EFFACE LE DISQUE)
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

- [ ] Clé USB créée
- [ ] Backup données fait
- [ ] Boot sur USB
- [ ] WiFi connecté
- [ ] Repo cloné
- [ ] Device disk vérifié (nvme0n1)
- [ ] Disko executé
- [ ] Mot de passe LUKS défini (⚠️ noté quelque part)
- [ ] hardware-configuration.nix copié
- [ ] Installation lancée
- [ ] Mot de passe marcelo défini
- [ ] Reboot réussi
- [ ] Hyprland démarre
- [ ] Web apps fonctionnent

---

**Bonne installation ! 🚀**

*Simple, efficace, pas de chichi.* ✨
