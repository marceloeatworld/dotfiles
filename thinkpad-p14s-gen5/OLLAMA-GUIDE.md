# 🤖 GUIDE OLLAMA - AMD RADEON 780M

Configuration complète Ollama avec accélération GPU AMD pour ThinkPad P14s Gen 5.

---

## ✅ **CONFIGURATION INSTALLÉE**

### **Service Ollama:**
- ✅ Service systemd (démarrage auto)
- ✅ ROCm acceleration (AMD GPU)
- ✅ AMD Radeon 780M (gfx1103) support
- ✅ API REST sur `http://localhost:11434`
- ✅ Stockage: `/var/lib/ollama`

### **Clients TUI:**
- ✅ **aichat** - CLI ultra léger (Rust) - Usage quotidien
- ✅ **parllama** - TUI riche - Tests & comparaisons

---

## 🚀 **APRÈS INSTALLATION**

### **1. Vérifier le service:**

```bash
# Status du service
systemctl status ollama

# Logs en temps réel
journalctl -fu ollama

# Tester l'API
curl http://localhost:11434/api/tags
```

### **2. Vérifier GPU AMD:**

```bash
# Voir les variables ROCm
echo $HSA_OVERRIDE_GFX_VERSION  # Devrait afficher: 11.0.0

# Tester ROCm
rocminfo | grep gfx1103

# Vérifier GPU Ollama
ollama ps  # Une fois un modèle lancé
```

---

## 📥 **TÉLÉCHARGER DES MODÈLES**

### **Modèles recommandés pour 32GB RAM + 4GB VRAM:**

```bash
# Petit & rapide (3B - 2GB)
ollama pull llama3.2:3b

# Équilibré (7B - 4GB) ⭐ RECOMMANDÉ
ollama pull mistral:7b

# Qualité (8B - 5GB)
ollama pull llama3.1:8b

# Coding (7B - 4GB)
ollama pull codellama:7b

# Vision (11B - 7GB)
ollama pull llava:7b

# DeepSeek Coder (7B - 4GB)
ollama pull deepseek-coder:6.7b
```

### **Lister les modèles installés:**

```bash
ollama list
```

### **Supprimer un modèle:**

```bash
ollama rm mistral:7b
```

---

## 💬 **UTILISER AICHAT (quotidien)**

### **Configuration initiale:**

```bash
# Premier lancement (crée ~/.config/aichat/config.yaml)
aichat

# Puis éditer la config:
nvim ~/.config/aichat/config.yaml
```

**Config recommandée:**
```yaml
model: ollama:mistral
temperature: 0.7
save: true
highlight: true
light_theme: false
wrap: auto
wrap_code: false
```

### **Utilisation:**

```bash
# Chat interactif
aichat

# Question rapide
aichat "Explain quantum computing in simple terms"

# Avec un modèle spécifique
aichat -m ollama:llama3.1 "What is Rust?"

# Mode code (copie automatique)
aichat -C "Write a Fibonacci function in Python"

# Depuis stdin
echo "Explain this error" | aichat

# Mode développeur (markdown brut)
aichat -r "Generate API documentation"

# Avec fichier context
aichat -f code.py "Explain this code"

# Chat session avec nom
aichat -s "rust-learning" "How do I use traits?"
```

### **Raccourcis dans aichat:**

| Raccourci | Action |
|-----------|--------|
| `.help` | Aide |
| `.model mistral` | Changer modèle |
| `.info` | Info session |
| `.clear` | Clear screen |
| `.exit` | Quitter |
| `.copy` | Copier dernière réponse |
| `.read file.txt` | Lire fichier |

---

## 🎨 **UTILISER PARLLAMA (tests)**

### **Lancement:**

```bash
# Via Wofi
SUPER + D → "parllama" → Enter

# Ou en terminal
parllama
```

### **Interface parllama:**

```
┌─────────────────────────────────────────────┐
│ Models | Chat | Sessions | Settings         │
├─────────────────────────────────────────────┤
│                                             │
│  📦 Available Models:                       │
│  ● mistral:7b              4.1GB            │
│  ● llama3.1:8b             4.7GB            │
│  ● codellama:7b            3.8GB            │
│                                             │
│  [Pull Model] [Delete] [View Info]          │
│                                             │
├─────────────────────────────────────────────┤
│ > Your message here...                      │
└─────────────────────────────────────────────┘
```

### **Fonctionnalités parllama:**

- 📦 **Télécharger modèles** visuellement
- 💬 **Multi-sessions** avec noms
- 🎨 **Thèmes** (dark/light/custom)
- 📊 **Stats** (tokens/s, VRAM usage)
- 🖼️ **Images** (avec vision models)
- 📚 **Prompt library**
- 🔄 **Comparaison** modèles côte à côte

---

## ⚡ **PERFORMANCE ATTENDUE**

### **Benchmarks Radeon 780M (ROCm):**

| Modèle | Taille | VRAM | Tokens/s (GPU) | Utilité |
|--------|--------|------|----------------|---------|
| llama3.2:3b | 2GB | 2-3GB | 40-60 | Rapide, tests |
| mistral:7b | 4GB | 4-5GB | 25-35 | ⭐ Quotidien |
| llama3.1:8b | 5GB | 5-6GB | 20-30 | Qualité |
| codellama:7b | 4GB | 4-5GB | 25-35 | Coding |
| deepseek-coder:6.7b | 4GB | 4-5GB | 25-30 | Coding++ |
| llava:7b | 7GB | 7-8GB | 15-25 | Vision |

**Note:** Avec 4GB VRAM, les modèles 7B-8B utilisent un mix RAM+VRAM (offloading).

---

## 🔧 **OPTIMISATIONS**

### **1. Activer GPU dans aichat:**

```yaml
# ~/.config/aichat/config.yaml
model: ollama:mistral
clients:
  - type: ollama
    api_base: http://localhost:11434
    models:
      - name: mistral
        max_tokens: 4096
```

### **2. Variables ROCm (déjà configurées):**

Les variables suivantes sont automatiquement définies par le service Ollama:

```bash
HSA_OVERRIDE_GFX_VERSION=11.0.0  # Fix RDNA 3
ROCR_VISIBLE_DEVICES=0           # GPU 0
ROC_ENABLE_PRE_VEGA=1            # Compat
```

### **3. Augmenter VRAM si nécessaire:**

Si vous avez besoin de plus de VRAM pour gros modèles:

```bash
# BIOS → Advanced → UMA Frame Buffer Size → 4GB ou 8GB
# (Redémarrage requis)
```

---

## 🌐 **API OLLAMA**

### **Endpoints:**

```bash
# Liste des modèles
curl http://localhost:11434/api/tags

# Générer texte
curl http://localhost:11434/api/generate -d '{
  "model": "mistral",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

# Chat
curl http://localhost:11434/api/chat -d '{
  "model": "mistral",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ],
  "stream": false
}'

# Pull modèle
curl http://localhost:11434/api/pull -d '{
  "name": "mistral"
}'

# Embeddings
curl http://localhost:11434/api/embeddings -d '{
  "model": "mistral",
  "prompt": "Hello world"
}'
```

---

## 🔌 **INTÉGRATIONS**

### **1. VS Code (Continue.dev):**

```json
// settings.json
{
  "continue.modelProvider": "ollama",
  "continue.ollamaBaseUrl": "http://localhost:11434",
  "continue.modelName": "mistral"
}
```

### **2. Script shell:**

```bash
#!/usr/bin/env bash
# ask.sh - Quick AI assistant

question="$*"
aichat "$question"
```

```bash
chmod +x ask.sh
./ask.sh What is the capital of France?
```

### **3. Zsh alias:**

```bash
# ~/.zshrc ou modules/home/programs/shell.nix
alias ask='aichat'
alias ai='aichat -C'  # Code mode
alias explain='aichat "Explain: "'
```

---

## 📊 **MONITORING**

### **Voir utilisation GPU:**

```bash
# AMD GPU stats
watch -n 1 rocm-smi

# Ou
watch -n 1 "cat /sys/class/drm/card*/device/gpu_busy_percent"

# VRAM usage
rocm-smi --showmeminfo vram
```

### **Logs Ollama:**

```bash
# Logs temps réel
journalctl -fu ollama

# Logs avec erreurs seulement
journalctl -u ollama -p err
```

---

## 🐛 **DÉPANNAGE**

### **Problème: GPU non détecté**

```bash
# Vérifier ROCm
rocminfo | grep gfx

# Si vide, installer ROCm:
nix-shell -p rocmPackages.rocminfo

# Vérifier variables
env | grep HSA
env | grep ROC
```

### **Problème: Slow performance**

```bash
# Vérifier que GPU est utilisé
ollama ps  # Devrait montrer VRAM usage

# Si CPU only, vérifier:
systemctl status ollama
journalctl -u ollama | grep -i rocm
```

### **Problème: Out of memory**

```bash
# Utiliser version quantized plus petite
ollama pull mistral:7b-q4_0  # 4-bit quantization

# Ou modèle plus petit
ollama pull llama3.2:3b
```

### **Problème: aichat ne trouve pas Ollama**

```bash
# Vérifier service
systemctl status ollama

# Tester API
curl http://localhost:11434/api/tags

# Config aichat
cat ~/.config/aichat/config.yaml
```

---

## 📚 **RESSOURCES**

- **Ollama library:** https://ollama.com/library
- **aichat docs:** https://github.com/sigoden/aichat
- **parllama docs:** https://github.com/paulrobello/parllama
- **ROCm docs:** https://rocm.docs.amd.com/

---

## 🎯 **WORKFLOW RECOMMANDÉ**

### **Usage quotidien:**

```bash
# 1. Chat rapide
aichat "Quick question here"

# 2. Coding help
aichat -C "Write a function to parse JSON"

# 3. Explain code
aichat -f myfile.py "What does this do?"

# 4. Session longue
aichat -s "project-x" "Let's discuss architecture"
```

### **Tests & comparaisons:**

```bash
# Lancer parllama
parllama

# → Télécharger plusieurs modèles
# → Comparer réponses côte à côte
# → Tester avec images (vision models)
```

---

## ✨ **RÉSUMÉ**

| Besoin | Outil | Commande |
|--------|-------|----------|
| **Question rapide** | aichat | `aichat "question"` |
| **Coding** | aichat | `aichat -C "code task"` |
| **Chat long** | aichat | `aichat -s "session"` |
| **Tests modèles** | parllama | `parllama` |
| **Télécharger** | ollama | `ollama pull mistral` |
| **API** | curl | `curl localhost:11434/api/generate` |

---

**Simple, efficace, AMD-optimisé !** 🚀
