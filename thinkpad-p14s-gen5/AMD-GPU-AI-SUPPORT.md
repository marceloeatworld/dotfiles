# AMD Radeon 780M GPU - Support IA et Configuration

## Vue d'ensemble

Votre **AMD Radeon 780M (gfx1103)** peut être utilisé pour l'IA et le machine learning avec ROCm!

---

## 🎯 Résultat: OUI, Vous Pouvez Utiliser Votre GPU pour l'IA!

### Statut Support ROCm:
- ✅ **Support communautaire**: Radeon 780M (gfx1103)
- ⚠️ **Support officiel**: Limité (preview pour APU Ryzen)
- ✅ **Workaround disponible**: HSA_OVERRIDE_GFX_VERSION=11.0.0
- ✅ **Fonctionnel**: PyTorch, LLaMA, Stable Diffusion

---

## Configuration ROCm pour Radeon 780M

### 🔴 Variable Critique à Ajouter

Pour utiliser ROCm avec le Radeon 780M, vous devez définir:

```bash
HSA_OVERRIDE_GFX_VERSION=11.0.0
```

Cette variable force ROCm à traiter votre GPU comme un gfx1100 (officiellement supporté).

### ✅ Ajout à Votre Configuration

Éditez `modules/home/programs/hyprland.nix` ou créez `modules/home/config/ai.nix`:

```nix
# AI/ML environment variables pour Radeon 780M
home.sessionVariables = {
  # ROCm support pour Radeon 780M (gfx1103)
  HSA_OVERRIDE_GFX_VERSION = "11.0.0";

  # ROCm paths
  ROCM_PATH = "/opt/rocm";

  # PyTorch ROCm
  PYTORCH_ROCM_ARCH = "gfx1100";

  # Disable cache (for testing, remove after confirmed working)
  # HSA_ENABLE_SDMA = "0";
};
```

**Ou ajoutez directement aux environment variables Hyprland:**

```nix
env = [
  # ... existing variables

  # ROCm support pour IA/ML
  "HSA_OVERRIDE_GFX_VERSION,11.0.0"
  "ROCM_PATH,/opt/rocm"
  "PYTORCH_ROCM_ARCH,gfx1100"
];
```

---

## Packages IA à Installer

### Option 1: PyTorch avec ROCm (Recommandé)

Ajoutez à `modules/home/programs/development.nix` ou `modules/home/programs/ai.nix`:

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ROCm core (déjà dans votre system config)
    # rocmPackages.clr.icd  # Déjà configuré

    # Python AI/ML stack
    python3Packages.torch  # PyTorch avec ROCm
    python3Packages.torchvision
    python3Packages.numpy
    python3Packages.pandas
    python3Packages.scikit-learn

    # LLM tools
    ollama         # Run LLMs locally (Llama, Mistral, etc.)
    # llama-cpp    # Alternative LLM runtime

    # Image generation
    # stable-diffusion-cpp  # Stable Diffusion sur GPU
  ];
}
```

### Option 2: Ollama (Plus Simple)

Pour commencer rapidement avec les LLMs:

```nix
home.packages = with pkgs; [
  ollama  # LLM runtime (Llama 3, Mistral, etc.)
];

# Service Ollama
systemd.user.services.ollama = {
  Unit = {
    Description = "Ollama LLM Service";
  };
  Service = {
    ExecStart = "${pkgs.ollama}/bin/ollama serve";
    Environment = [
      "HSA_OVERRIDE_GFX_VERSION=11.0.0"
      "OLLAMA_HOST=127.0.0.1:11434"
    ];
  };
  Install = {
    WantedBy = [ "default.target" ];
  };
};
```

Puis utilisez:

```bash
# Télécharger et lancer un modèle
ollama run llama3.2

# Ou un modèle plus petit pour votre iGPU
ollama run llama3.2:1b
ollama run phi3:mini
```

---

## Performances Attendues

### Radeon 780M Specs:
- **Architecture**: RDNA 3
- **Compute Units**: 12 CU
- **Stream Processors**: 768 SP
- **Clock**: 2700 MHz
- **Memory**: Shared system RAM (jusqu'à 6-8 GB)
- **Compute Performance**: ~4.1 TFLOPS FP32

### Comparaison:

| GPU | TFLOPS FP32 | LLM Speed (7B) |适用于 |
|-----|-------------|----------------|---------|
| **Radeon 780M (vous)** | ~4.1 | ~3-5 tokens/s | Petits modèles, inference |
| Radeon RX 7900 XTX | 61 | ~50-60 tokens/s | Tous modèles |
| RTX 4070 | 29 | ~25-30 tokens/s | Gros modèles |
| RTX 3060 12GB | 13 | ~15-20 tokens/s | Modèles moyens |

### Ce Que Vous Pouvez Faire:

✅ **Fonctionne Bien:**
- LLMs petits/moyens (1B-3B paramètres): Phi-3, Llama 3.2 1B/3B
- Inference image classification
- Fine-tuning petits modèles
- Stable Diffusion (résolution réduite)
- Expérimentations et apprentissage

⚠️ **Lent Mais Possible:**
- LLMs moyens (7B-13B): Llama 3.2 7B, Mistral 7B
- Stable Diffusion SD 1.5/2.1
- Training petits modèles

❌ **Trop Lent:**
- Gros LLMs (70B+): Llama 3.1 70B
- Très haute résolution image generation
- Training gros modèles

---

## Tests à Faire Après Installation

### Test 1: ROCm Detection

```bash
# Vérifier ROCm
rocminfo

# Devrait montrer:
# Agent 2: AMD Radeon 780M
# Name: gfx1103
```

### Test 2: PyTorch GPU

```bash
python3 << EOF
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"ROCm available: {torch.cuda.is_available()}")  # Oui, torch.cuda pour ROCm aussi
print(f"GPU count: {torch.cuda.device_count()}")
if torch.cuda.is_available():
    print(f"GPU name: {torch.cuda.get_device_name(0)}")
    print(f"GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
EOF
```

**Sortie attendue:**
```
PyTorch version: 2.x.x
ROCm available: True
GPU count: 1
GPU name: gfx1103
GPU memory: 6.0 GB (ou plus selon votre RAM)
```

### Test 3: Ollama avec GPU

```bash
# Lancer Ollama
ollama serve &

# Tester un petit modèle
ollama run phi3:mini

# Surveiller l'usage GPU
watch -n 1 rocm-smi

# Devrait montrer activité GPU pendant l'inférence
```

### Test 4: Benchmark Simple

```python
import torch
import time

# Créer tenseurs sur GPU
x = torch.randn(1000, 1000).cuda()
y = torch.randn(1000, 1000).cuda()

# Benchmark multiplication matricielle
start = time.time()
for _ in range(100):
    z = torch.matmul(x, y)
torch.cuda.synchronize()
end = time.time()

print(f"GPU matmul: {(end-start)*1000:.2f}ms pour 100 itérations")
print(f"Performance: {100/(end-start):.1f} matmuls/seconde")
```

---

## Optimisations AMD pour IA

### 1. Augmenter Shared GPU Memory (BIOS)

Dans le BIOS ThinkPad:
- **Config → Display → UMA Frame Buffer Size**
- Augmenter à **4GB ou 6GB** (au lieu de 2GB default)
- Plus de VRAM = modèles plus gros possibles

### 2. Kernel Parameters pour Performance

Déjà configuré dans votre `modules/system/amd-optimizations.nix`:

```nix
boot.kernelParams = [
  "amd_pstate=active"           # ✅ Déjà configuré
  "amdgpu.ppfeaturemask=0xffffffff"  # ✅ Déjà configuré
  "amdgpu.gpu_recovery=1"       # ✅ Déjà configuré
];
```

### 3. Power Profile pour ML

Créez un profil power pour ML workloads:

```nix
# modules/system/power-ml.nix
{ pkgs, ... }:

{
  # Power profile pour ML/AI (performance maximale)
  services.power-profiles-daemon.enable = true;

  # Script pour basculer en mode performance
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "ml-mode" ''
      # Passer en mode performance
      powerprofilesctl set performance

      # Fixer GPU à max freq
      echo "Setting GPU to performance mode..."
      echo "manual" > /sys/class/drm/card0/device/power_dpm_force_performance_level
      echo "1" > /sys/class/drm/card0/device/power_dpm_state

      echo "ML Performance mode enabled!"
    '')

    (writeShellScriptBin "normal-mode" ''
      # Retour au mode balancé
      powerprofilesctl set balanced

      # GPU auto
      echo "auto" > /sys/class/drm/card0/device/power_dpm_force_performance_level

      echo "Normal mode restored!"
    '')
  ];
}
```

Usage:
```bash
# Avant d'utiliser ML/AI
ml-mode

# Après le travail
normal-mode
```

---

## Modèles Recommandés pour Radeon 780M

### LLMs (via Ollama):

**Petits (Rapides):**
```bash
ollama run phi3:mini        # 3.8B, très rapide
ollama run llama3.2:1b      # 1.2B, ultra rapide
ollama run tinyllama        # 1.1B, expérimental
```

**Moyens (Utilisables):**
```bash
ollama run llama3.2:3b      # 3.2B, bon équilibre
ollama run mistral:7b       # 7B, qualité/vitesse
ollama run gemma2:2b        # 2B, Google
```

**Utilisation:**
```bash
# Chat interactif
ollama run phi3:mini "Explique-moi les tenseurs PyTorch"

# Via API
curl http://localhost:11434/api/generate -d '{
  "model": "phi3:mini",
  "prompt": "Pourquoi le ciel est bleu?"
}'
```

### Stable Diffusion:

**Via ComfyUI (recommandé):**
```nix
home.packages = with pkgs; [
  # ComfyUI pour Stable Diffusion
  python3Packages.pytorch
  git  # Pour cloner ComfyUI
];
```

```bash
# Installer ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install -r requirements.txt

# Lancer avec ROCm
HSA_OVERRIDE_GFX_VERSION=11.0.0 python main.py --listen
```

**Modèles recommandés:**
- SD 1.5 (512x512): ~15-30 sec/image
- SD XL (1024x1024): ~60-120 sec/image
- SDXL Turbo: ~10-20 sec/image

---

## Configuration Complète NixOS pour IA

Créez `modules/home/programs/ai.nix`:

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LLM Runtime
    ollama

    # Python ML Stack
    python3Packages.torch
    python3Packages.torchvision
    python3Packages.numpy
    python3Packages.pandas
    python3Packages.scikit-learn
    python3Packages.transformers  # Hugging Face
    python3Packages.accelerate

    # Development
    python3Packages.jupyter
    python3Packages.matplotlib
    python3Packages.seaborn

    # Tools
    rocminfo  # ROCm system info
  ];

  # Environment variables pour ROCm
  home.sessionVariables = {
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";
    ROCM_PATH = "/opt/rocm";
    PYTORCH_ROCM_ARCH = "gfx1100";
  };

  # Jupyter config
  programs.jupyter = {
    enable = true;
    kernels = {
      python3 = {
        displayName = "Python 3 (ROCm)";
        language = "python";
        env = {
          HSA_OVERRIDE_GFX_VERSION = "11.0.0";
        };
      };
    };
  };
}
```

Ajoutez à `modules/home/home.nix`:
```nix
imports = [
  # ... existing imports
  ./programs/ai.nix
];
```

---

## Ressources et Documentation

### ROCm:
- **Official Docs**: https://rocm.docs.amd.com/
- **Radeon Support**: https://rocm.docs.amd.com/projects/radeon/
- **GitHub Issues**: https://github.com/ROCm/ROCm/issues

### PyTorch ROCm:
- **Installation**: https://pytorch.org/get-started/locally/
- **ROCm Guide**: https://rocm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-pytorch.html

### Ollama:
- **Website**: https://ollama.ai/
- **Models**: https://ollama.ai/library
- **GitHub**: https://github.com/ollama/ollama

### Community:
- **ROCm/ROCm GitHub**: Issues et discussions
- **r/ROCm Reddit**: Support communautaire
- **r/LocalLLaMA**: LLM local resources

---

## Limitations et Alternatives

### Limitations Radeon 780M:

1. **VRAM limitée**: Shared system RAM (2-8GB selon BIOS)
   - **Solution**: Utiliser modèles quantifiés (4-bit, 8-bit)

2. **Performance modeste**: ~4 TFLOPS vs 60+ pour GPU dédiés
   - **Solution**: Petits modèles, patience, ou cloud (Colab, Runpod)

3. **Support ROCm non-officiel**: Peut casser avec updates
   - **Solution**: NixOS rollback, version pinning

### Alternatives si Trop Lent:

**Cloud Gratuit:**
- Google Colab (free T4 GPU)
- Kaggle Notebooks (free P100 GPU)
- Lightning.ai (free GPU tiers)

**Cloud Payant:**
- RunPod: ~$0.20/hr GPU (RTX 4090)
- Vast.ai: À partir de $0.10/hr
- Lambda Labs: GPU cloud à la demande

**eGPU (Future):**
- Thunderbolt 4 eGPU enclosure
- Radeon RX 7600 XT (~$300) ou RTX 4060 (~$300)
- Performance 5-10x meilleure

---

## Verdict Final

### ✅ Radeon 780M pour IA: Utilisable!

**Pour Quoi:**
- ⭐⭐⭐ Apprentissage ML/AI (excellent)
- ⭐⭐⭐ Petits modèles LLM (bon)
- ⭐⭐ Modèles moyens 7B (acceptable)
- ⭐ Image generation SD (lent mais ok)
- ❌ Gros modèles 70B+ (trop lent)

**Configuration:**
1. ✅ ROCm déjà installé (votre config)
2. ✅ Kernel params optimisés (déjà fait)
3. ⚠️ Ajouter `HSA_OVERRIDE_GFX_VERSION=11.0.0`
4. ⚠️ Augmenter UMA buffer dans BIOS (4-6GB)
5. ✅ Installer PyTorch ou Ollama

**Recommandation:**
- Commencez avec **Ollama + petits modèles** (phi3:mini)
- Testez la performance
- Si satisfait → explorez plus (PyTorch, Stable Diffusion)
- Si trop lent → cloud ou eGPU future

**Votre GPU est parfait pour:**
- 🎓 Apprendre ML/AI
- 🧪 Prototyper et expérimenter
- 💬 Chatbots locaux (privacy)
- 🖼️ Image generation occasionnelle
- 📝 Code assistants locaux

🚀 **Allez-y et expérimentez!**
