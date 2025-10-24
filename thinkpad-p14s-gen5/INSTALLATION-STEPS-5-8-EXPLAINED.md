# 🔍 EXPLICATION DÉTAILLÉE - ÉTAPES 5 À 8

Guide détaillé des étapes critiques de l'installation (préparation disque).

---

## 📋 **VUE D'ENSEMBLE**

Ces 4 étapes préparent votre disque **AVANT** l'installation de NixOS:

| Étape | Quoi | Pourquoi |
|-------|------|----------|
| **5** | Vérifier config disque | S'assurer que le bon disque sera formaté |
| **6** | Disko (partitionnement) | Créer partitions + chiffrement + Btrfs |
| **7** | Vérifier montage | Confirmer que tout est prêt |
| **8** | Générer hardware config | Détecter votre matériel spécifique |

---

# 📊 ÉTAPE 5: VÉRIFIER LA CONFIGURATION DISQUE

## **Que fait cette étape ?**

Vous vérifiez que **disko-config.nix** va formater le **bon disque**.

## **Commandes:**

```bash
# Lister TOUS les disques de votre PC
lsblk
```

## **Résultat attendu:**

```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nvme0n1     259:0    0   1TB  0 disk              ← VOTRE SSD 1TB
├─nvme0n1p1 259:1    0   512M 0 part /boot/efi    (Windows existant)
├─nvme0n1p2 259:2    0   128M 0 part              (Windows)
├─nvme0n1p3 259:3    0   900G 0 part              (Windows)
└─nvme0n1p4 259:4    0   100G 0 part              (Windows)
sda         8:0      1    32G 0 disk              ← CLÉ USB (Live USB)
└─sda1      8:1      1    32G 0 part /run/media/nixos
```

## **Ce qu'il faut comprendre:**

### **1. Identifier votre SSD:**
- **nvme0n1** = SSD NVMe (1TB) ✅ C'est celui-là !
- **sda** = Clé USB (Live USB) ❌ Pas toucher !

### **2. Vérifier dans disko-config.nix:**

```bash
# Ouvrir le fichier
nano hosts/thinkpad/disko-config.nix

# Ligne 10:
device = "/dev/nvme0n1";  # ← Doit correspondre à votre SSD
```

### **3. Si votre SSD n'est PAS nvme0n1:**

**Exemples de noms possibles:**
- `/dev/nvme1n1` (si 2 SSD NVMe)
- `/dev/sda` (si SSD SATA)
- `/dev/vda` (si VM)

**Modifier le fichier:**
```bash
nano hosts/thinkpad/disko-config.nix

# Changer ligne 10:
device = "/dev/nvme1n1";  # Exemple si votre SSD est nvme1n1
```

## **⚠️ IMPORTANT:**

**Si vous vous trompez de disque:**
- ❌ Vous formaterez le mauvais disque
- ❌ Perte de données sur ce disque
- ❌ Peut-être votre clé USB au lieu du SSD

**→ VÉRIFIEZ TROIS FOIS !**

---

# 💾 ÉTAPE 6: DISKO - PARTITIONNEMENT AUTOMATIQUE

## **Qu'est-ce que Disko ?**

**Disko** = outil NixOS qui automatise le partitionnement selon un fichier déclaratif.

**Au lieu de faire manuellement:**
```bash
fdisk /dev/nvme0n1        # Créer partitions
cryptsetup luksFormat     # Chiffrer
mkfs.btrfs                # Formatter Btrfs
btrfs subvolume create    # Créer 7 sous-volumes
mount ...                 # Monter tout
```

**Disko fait TOUT en une commande !**

---

## **Commande:**

```bash
nix --extra-experimental-features 'nix-command flakes' \
    run github:nix-community/disko -- \
    --mode disko \
    hosts/thinkpad/disko-config.nix
```

## **Décomposition de la commande:**

| Partie | Explication |
|--------|-------------|
| `nix --extra-experimental-features 'nix-command flakes'` | Active les flakes (pas encore stable en 25.05) |
| `run github:nix-community/disko` | Télécharge et exécute Disko depuis GitHub |
| `--mode disko` | Mode "destruction" (formate le disque) |
| `hosts/thinkpad/disko-config.nix` | Votre fichier de config |

---

## **Ce que Disko va faire (étape par étape):**

### **1. DÉTRUIRE le disque /dev/nvme0n1** ⚠️
```
⚠️  Toutes les données sur nvme0n1 seront PERDUES !
```

### **2. Créer 2 partitions GPT:**

```
/dev/nvme0n1
├─ nvme0n1p1  1GB    EFI System Partition (ESP)  → /boot
└─ nvme0n1p2  999GB  LUKS encrypted             → crypted
```

**Pourquoi 2 partitions ?**
- **ESP (1GB):** Boot (non chiffré, requis pour UEFI)
- **LUKS (reste):** Tout le système chiffré

### **3. Formater ESP en FAT32:**

```bash
mkfs.vfat -F32 /dev/nvme0n1p1
```

### **4. Chiffrer nvme0n1p2 avec LUKS:**

```
┌─────────────────────────────────────┐
│ Enter passphrase for /dev/nvme0n1p2: █
└─────────────────────────────────────┘
```

**Ce qui se passe:**
1. Vous tapez un mot de passe (ex: `MonSuperMotDePasse123!`)
2. LUKS chiffre la partition avec **AES-256**
3. Crée `/dev/mapper/crypted` (partition déchiffrée)

**⚠️ CRUCIAL:**
- Ce mot de passe sera demandé **À CHAQUE DÉMARRAGE**
- Si oublié → **IMPOSSIBLE de récupérer les données**
- Notez-le quelque part de sûr !

### **5. Formater en Btrfs:**

```bash
mkfs.btrfs -f -L nixos /dev/mapper/crypted
```

Crée un filesystem Btrfs nommé "nixos".

### **6. Créer 7 sous-volumes Btrfs:**

```
/dev/mapper/crypted (Btrfs)
├─ @root       → /              (système)
├─ @home       → /home          (vos fichiers)
├─ @nix        → /nix           (paquets NixOS)
├─ @persist    → /persist       (données persistantes)
├─ @log        → /var/log       (logs système)
├─ @snapshots  → /.snapshots    (sauvegardes)
└─ @swap       → /swap          (swap file 16GB)
```

**Pourquoi des sous-volumes ?**
- Snapshots indépendants (restaurer @home sans toucher @root)
- Optimisations différentes (@nix sans COW)
- Organisation propre

### **7. Monter tout dans /mnt:**

```
/mnt
├─ /mnt              (@ root)
├─ /mnt/boot         (nvme0n1p1 - ESP)
├─ /mnt/home         (@home)
├─ /mnt/nix          (@nix)
├─ /mnt/persist      (@persist)
├─ /mnt/var/log      (@log)
├─ /mnt/.snapshots   (@snapshots)
└─ /mnt/swap         (@swap)
```

### **8. Créer le swapfile:**

```bash
# Dans /mnt/swap (@swap subvolume)
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=16384  # 16GB
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile
```

---

## **Résumé visuel de l'étape 6:**

**AVANT (Windows par exemple):**
```
/dev/nvme0n1 (1TB)
├─ Windows Boot
├─ Windows System
└─ Windows Data
```

**APRÈS Disko:**
```
/dev/nvme0n1 (1TB)
├─ nvme0n1p1 (1GB)   → /boot (FAT32)
└─ nvme0n1p2 (999GB) → LUKS "crypted" (AES-256)
                       └─ Btrfs "nixos"
                          ├─ @root      → /
                          ├─ @home      → /home
                          ├─ @nix       → /nix
                          ├─ @persist   → /persist
                          ├─ @log       → /var/log
                          ├─ @snapshots → /.snapshots
                          └─ @swap      → /swap (16GB swapfile)
```

---o

## **Durée de l'étape 6:**

- **Partitionnement:** 5 secondes
- **Chiffrement LUKS:** 2-5 minutes (selon SSD)
- **Btrfs format:** 10 secondes
- **Sous-volumes:** 5 secondes
- **Swapfile:** 1-2 minutes

**Total: ~5-10 minutes**

---

# ✅ ÉTAPE 7: VÉRIFIER LE MONTAGE

## **Que fait cette étape ?**

Confirmer que Disko a **correctement** monté tous les sous-volumes.

## **Commandes:**

```bash
# Voir tous les montages dans /mnt
mount | grep /mnt

# Voir l'espace disque
df -h /mnt
```

## **Résultat attendu:**

```bash
$ mount | grep /mnt

/dev/mapper/crypted on /mnt type btrfs (rw,noatime,compress=zstd,space_cache=v2,subvolid=256,subvol=/@root)
/dev/nvme0n1p1 on /mnt/boot type vfat (rw,relatime,fmask=0077,dmask=0077)
/dev/mapper/crypted on /mnt/home type btrfs (rw,noatime,compress=zstd,space_cache=v2,subvolid=257,subvol=/@home)
/dev/mapper/crypted on /mnt/nix type btrfs (rw,noatime,compress=zstd,space_cache=v2,nocowd,subvolid=258,subvol=/@nix)
/dev/mapper/crypted on /mnt/persist type btrfs (rw,noatime,compress=zstd,space_cache=v2,subvolid=259,subvol=/@persist)
/dev/mapper/crypted on /mnt/var/log type btrfs (rw,noatime,compress=zstd,space_cache=v2,subvolid=260,subvol=/@log)
/dev/mapper/crypted on /mnt/.snapshots type btrfs (rw,noatime,compress=zstd,space_cache=v2,subvolid=261,subvol=/@snapshots)
/dev/mapper/crypted on /mnt/swap type btrfs (rw,noatime,subvolid=262,subvol=/@swap)
```

## **Ce qu'il faut vérifier:**

### **1. Tous les 8 montages sont présents:**
- ✅ `/mnt` (@root)
- ✅ `/mnt/boot` (ESP)
- ✅ `/mnt/home` (@home)
- ✅ `/mnt/nix` (@nix)
- ✅ `/mnt/persist` (@persist)
- ✅ `/mnt/var/log` (@log)
- ✅ `/mnt/.snapshots` (@snapshots)
- ✅ `/mnt/swap` (@swap)

### **2. Options de montage correctes:**

**Pour @root, @home, @persist, @log, @snapshots:**
```
compress=zstd       ← Compression active
noatime             ← Pas de mise à jour access time (performance)
space_cache=v2      ← Cache Btrfs moderne
```

**Pour @nix:**
```
nocowd              ← Pas de Copy-on-Write (performance bases de données)
```

### **3. Espace disque disponible:**

```bash
$ df -h /mnt

Filesystem           Size  Used Avail Use% Mounted on
/dev/mapper/crypted  999G  1.2G  997G   1% /mnt
```

**Devrait montrer ~999GB disponibles** (1TB - 1GB boot)

---

## **Si quelque chose manque:**

### **Problème: Un montage manque**

```bash
# Relancer Disko
nix run github:nix-community/disko -- --mode disko hosts/thinkpad/disko-config.nix
```

### **Problème: /dev/mapper/crypted n'existe pas**

```bash
# LUKS n'a pas été ouvert
cryptsetup luksOpen /dev/nvme0n1p2 crypted
# Entrer le mot de passe LUKS
```

---

# 🖥️ ÉTAPE 8: GÉNÉRER hardware-configuration.nix

## **Que fait cette étape ?**

NixOS **détecte automatiquement** votre matériel et crée un fichier de configuration.

## **Pourquoi nécessaire ?**

Chaque PC est différent:
- CPU AMD vs Intel
- Carte réseau différente
- Disques différents
- Modules kernel spécifiques

**hardware-configuration.nix** contient ces détails spécifiques à VOTRE ThinkPad.

---

## **Commande:**

```bash
# Générer la config dans /mnt/etc/nixos/
nixos-generate-config --root /mnt
```

## **Ce que fait cette commande:**

### **1. Scanne votre matériel:**
- CPU (AMD Ryzen 7 PRO 8840HS)
- GPU (Radeon 780M)
- WiFi/Ethernet
- Bluetooth
- Disques (NVMe, USB, etc.)
- Modules kernel nécessaires

### **2. Détecte les partitions montées:**
```bash
# Voit que /mnt est monté sur /dev/mapper/crypted
# Voit que /mnt/boot est sur /dev/nvme0n1p1
# Etc.
```

### **3. Génère 2 fichiers:**

```
/mnt/etc/nixos/
├─ configuration.nix           ← Config de base (on n'utilise pas)
└─ hardware-configuration.nix  ← ⭐ Celui qu'on veut !
```

---

## **Copier dans votre config:**

```bash
# Copier hardware-configuration.nix dans votre dotfiles
cp /mnt/etc/nixos/hardware-configuration.nix \
   hosts/thinkpad/hardware-configuration.nix
```

---

## **Contenu de hardware-configuration.nix:**

### **1. Imports de modules:**
```nix
imports = [
  <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
];
```

### **2. Boot loader:**
```nix
boot.initrd.availableKernelModules = [
  "nvme"        # Support NVMe SSD
  "xhci_pci"    # USB 3.0
  "ahci"        # SATA
  "usb_storage" # Clés USB
  "sd_mod"      # Cartes SD
  "rtsx_pci_sdmmc"  # Lecteur SD ThinkPad
];

boot.initrd.kernelModules = [ ];
boot.kernelModules = [ "kvm-amd" ];  # Virtualisation AMD
boot.extraModulePackages = [ ];
```

**Important:** `kvm-amd` active la virtualisation (VMware, QEMU).

### **3. LUKS (CRITIQUE):**
```nix
boot.initrd.luks.devices."crypted" = {
  device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
  preLVM = true;
};
```

**Ce que ça fait:**
- Au boot, avant de monter `/`, NixOS demande le mot de passe LUKS
- Déchiffre `/dev/nvme0n1p2`
- Crée `/dev/mapper/crypted`
- Monte les sous-volumes Btrfs

**Sans cette section → Impossible de booter !**

### **4. Filesystems:**
```nix
fileSystems."/" = {
  device = "/dev/mapper/crypted";
  fsType = "btrfs";
  options = [ "subvol=@root" "compress=zstd" "noatime" ];
};

fileSystems."/boot" = {
  device = "/dev/disk/by-uuid/XXXX-XXXX";  # UUID de nvme0n1p1
  fsType = "vfat";
};

fileSystems."/home" = {
  device = "/dev/mapper/crypted";
  fsType = "btrfs";
  options = [ "subvol=@home" "compress=zstd" "noatime" ];
};

# ... même chose pour /nix, /persist, /var/log, etc.
```

### **5. Swapfile:**
```nix
swapDevices = [{
  device = "/swap/swapfile";
}];
```

### **6. Hardware:**
```nix
# CPU
nixpkgs.hostPlatform = "x86_64-linux";
hardware.cpu.amd.updateMicrocode = true;

# GPU
hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;  # Pour jeux 32-bit
};
```

---

## **Vérifier hardware-configuration.nix:**

```bash
cat hosts/thinkpad/hardware-configuration.nix
```

### **Ce qui DOIT être présent:**

✅ **Section LUKS:**
```nix
boot.initrd.luks.devices."crypted"
```

✅ **Tous les filesystems:**
- `/` (root)
- `/boot`
- `/home`
- `/nix`
- `/persist`
- `/var/log`
- `/.snapshots`
- `/swap`

✅ **Swapfile:**
```nix
swapDevices = [{ device = "/swap/swapfile"; }];
```

✅ **Modules AMD:**
```nix
boot.kernelModules = [ "kvm-amd" ];
hardware.cpu.amd.updateMicrocode = true;
```

---

## **Si quelque chose manque:**

### **Problème: Pas de section LUKS**

**Cause:** Disko n'a pas correctement chiffré ou monté.

**Solution:**
```bash
# Relancer Disko
umount -R /mnt
nix run github:nix-community/disko -- --mode disko hosts/thinkpad/disko-config.nix
nixos-generate-config --root /mnt
```

### **Problème: Filesystems manquants**

**Cause:** Sous-volumes Btrfs non montés.

**Solution:**
```bash
# Vérifier montages
mount | grep /mnt

# Si manquants, remonter manuellement
mount -o subvol=@persist /dev/mapper/crypted /mnt/persist
# Etc.

# Régénérer
nixos-generate-config --root /mnt --force
```

---

# 🎯 RÉSUMÉ DES ÉTAPES 5-8

## **Étape 5: Vérifier config disque**
- ✅ Identifier votre SSD (nvme0n1, nvme1n1, sda, etc.)
- ✅ Confirmer dans disko-config.nix
- ⚠️ **CRITIQUE:** Mauvais disque = perte de données

## **Étape 6: Disko (10 min)**
- ⚠️ **Détruit le disque complètement**
- ✅ Crée 2 partitions (ESP 1GB + LUKS 999GB)
- ✅ Chiffre avec LUKS (vous tapez un mot de passe)
- ✅ Formate en Btrfs
- ✅ Crée 7 sous-volumes
- ✅ Monte tout dans /mnt

## **Étape 7: Vérifier montage**
- ✅ Confirmer 8 montages présents
- ✅ Vérifier options (compress=zstd, noatime)
- ✅ Confirmer espace disque (~999GB)

## **Étape 8: Générer hardware config**
- ✅ Scanne votre matériel
- ✅ Détecte LUKS, Btrfs, subvolumes
- ✅ Copier dans hosts/thinkpad/
- ✅ Vérifier section LUKS présente

---

# ❓ QUESTIONS FRÉQUENTES

## **Q: Pourquoi LUKS (chiffrement) ?**
**R:** Sécurité. Si quelqu'un vole votre laptop, il ne peut pas lire vos données sans le mot de passe.

## **Q: Pourquoi Btrfs au lieu de ext4 ?**
**R:**
- Compression (gagne 30-50% espace)
- Snapshots (sauvegardes)
- Subvolumes (organisation)
- Scrub (détection erreurs)

## **Q: Pourquoi 7 sous-volumes ?**
**R:**
- Flexibilité (snapshot @home sans @root)
- Optimisations (@nix sans COW)
- Organisation propre

## **Q: Puis-je utiliser ext4 simple ?**
**R:** Oui, mais vous perdez:
- Compression (30-50% espace)
- Snapshots automatiques
- Protection données
- Flexibilité

## **Q: Le mot de passe LUKS, c'est quoi ?**
**R:**
- Tapé à l'étape 6 (Disko)
- Demandé à CHAQUE démarrage
- **Si oublié = données perdues définitivement**
- Choisir: long, complexe, mémorisable

## **Q: Combien de temps les étapes 5-8 ?**
**R:**
- Étape 5: 2 minutes (vérification)
- Étape 6: 5-10 minutes (Disko)
- Étape 7: 1 minute (vérification)
- Étape 8: 2 minutes (génération)

**Total: ~15-20 minutes**

---

**Questions sur ces étapes ?** 🤔
