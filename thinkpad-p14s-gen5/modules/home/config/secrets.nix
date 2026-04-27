# Secrets management via sops-nix (age encryption)
# Encrypted in repo (safe to commit), decrypted at rebuild to tmpfs
#
# Setup (one-time):
#   1. Run: secrets-setup
#   2. Edit secrets: sops ~/dotfiles/thinkpad-p14s-gen5/sops/api-keys.yaml
#   3. Rebuild: rebuild
#
# Add new key:
#   1. sops ~/dotfiles/thinkpad-p14s-gen5/sops/api-keys.yaml  (add key: value)
#   2. Add sops.secrets.<name> below
#   3. Add the secret to load-ai-secrets below
#   4. Rebuild
{ config, pkgs, ... }:

let
  dotfiles = "$HOME/dotfiles/thinkpad-p14s-gen5";

  # One-time setup script: generates age key, updates .sops.yaml, encrypts secrets
  secrets-setup = pkgs.writeShellScriptBin "secrets-setup" ''
    set -euo pipefail
    AGE_DIR="$HOME/.config/sops/age"
    AGE_KEY="$AGE_DIR/keys.txt"
    SOPS_CONF="${dotfiles}/.sops.yaml"
    SECRETS_FILE="${dotfiles}/sops/api-keys.yaml"

    echo "══════════════════════════════════════════"
    echo "  sops-nix secrets setup"
    echo "══════════════════════════════════════════"

    # Step 1: Generate age key if missing
    if [ -f "$AGE_KEY" ]; then
      echo "[OK] Age key already exists: $AGE_KEY"
    else
      mkdir -p "$AGE_DIR"
      ${pkgs.age}/bin/age-keygen -o "$AGE_KEY" 2>&1
      chmod 600 "$AGE_KEY"
      echo "[OK] Age key generated: $AGE_KEY"
    fi

    # Extract public key
    PUB_KEY=$(${pkgs.gnugrep}/bin/grep -oP 'public key: \K.*' "$AGE_KEY" 2>/dev/null \
      || ${pkgs.age}/bin/age-keygen -y "$AGE_KEY")
    echo ""
    echo "Public key: $PUB_KEY"

    # Step 2: Update .sops.yaml with actual public key
    if ${pkgs.gnugrep}/bin/grep -q "AGE_PUBLIC_KEY_PLACEHOLDER" "$SOPS_CONF" 2>/dev/null; then
      ${pkgs.gnused}/bin/sed -i "s|AGE_PUBLIC_KEY_PLACEHOLDER|$PUB_KEY|" "$SOPS_CONF"
      echo "[OK] Updated .sops.yaml with your public key"
    else
      echo "[OK] .sops.yaml already configured"
    fi

    # Step 3: Encrypt the secrets file if not already encrypted
    if ${pkgs.gnugrep}/bin/grep -q "sops:" "$SECRETS_FILE" 2>/dev/null; then
      echo "[OK] Secrets file already encrypted"
    else
      echo ""
      echo "Encrypting secrets file..."
      cd "${dotfiles}"
      ${pkgs.sops}/bin/sops --encrypt --in-place "$SECRETS_FILE"
      echo "[OK] Secrets file encrypted"
    fi

    echo ""
    echo "══════════════════════════════════════════"
    echo "  Setup complete!"
    echo "══════════════════════════════════════════"
    echo ""
    echo "Next steps:"
    echo "  1. Edit secrets:  sops ${dotfiles}/sops/api-keys.yaml"
    echo "  2. Rebuild:       rebuild"
    echo ""
    echo "Your API keys can be loaded into a shell with:"
    echo "  load-ai-secrets"
    echo ""
    echo "Or scoped to one command with:"
    echo "  with-ai-secrets <command> [args...]"
    echo ""
    echo "Available env vars:"
    echo "  FAL_KEY, HF_TOKEN, GEMINI_API_KEY,"
    echo "  GLM_API_KEY, MINIMAX_API_KEY, OPENAI_API_KEY, OPENROUTER_API_KEY,"
    echo "  GITHUB_PERSONAL_ACCESS_TOKEN, TFE_TOKEN"
  '';

in
{
  # Tools needed for secrets management
  home.packages = [
    pkgs.sops
    pkgs.age
    secrets-setup
  ];

  # sops-nix configuration
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../../sops/api-keys.yaml;

    secrets = {
      # AI providers
      gemini_api_key = {};      # Google Gemini
      glm_api_key = {};         # Z.AI GLM (Hermes coder, OpenCode)
      minimax_api_key = {};     # MiniMax (Hermes)
      openai_api_key = {};      # OpenAI compat
      openrouter_api_key = {};  # OpenRouter
      # Media / ML
      fal_key = {};             # fal.ai (image/video/audio generation)
      hf_token = {};            # HuggingFace (model downloads)
      # Dev platforms (MCP servers)
      github_personal_access_token = {};  # GitHub MCP
      tfe_token = {};                     # Terraform Cloud MCP
    };
  };

  # Keep decrypted secrets out of every interactive shell by default.
  # Use load-ai-secrets for the current shell, or with-ai-secrets for one command.
  programs.zsh.initContent = ''
    __load_sops_secret() {
      local env_name="$1"
      local secret_path="$2"
      [ -r "$secret_path" ] && export "$env_name=$(< "$secret_path")"
    }

    load-ai-secrets() {
      __load_sops_secret GEMINI_API_KEY "${config.sops.secrets.gemini_api_key.path}"
      __load_sops_secret GLM_API_KEY "${config.sops.secrets.glm_api_key.path}"
      __load_sops_secret MINIMAX_API_KEY "${config.sops.secrets.minimax_api_key.path}"
      __load_sops_secret OPENAI_API_KEY "${config.sops.secrets.openai_api_key.path}"
      __load_sops_secret OPENROUTER_API_KEY "${config.sops.secrets.openrouter_api_key.path}"
      __load_sops_secret FAL_KEY "${config.sops.secrets.fal_key.path}"
      __load_sops_secret HF_TOKEN "${config.sops.secrets.hf_token.path}"
      __load_sops_secret GITHUB_PERSONAL_ACCESS_TOKEN "${config.sops.secrets.github_personal_access_token.path}"
      __load_sops_secret TFE_TOKEN "${config.sops.secrets.tfe_token.path}"
    }

    unload-ai-secrets() {
      unset GEMINI_API_KEY GLM_API_KEY MINIMAX_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY FAL_KEY HF_TOKEN GITHUB_PERSONAL_ACCESS_TOKEN TFE_TOKEN
    }

    with-ai-secrets() {
      if [ "$#" -eq 0 ]; then
        echo "usage: with-ai-secrets <command> [args...]" >&2
        return 2
      fi

      (
        load-ai-secrets
        exec "$@"
      )
    }
  '';
}
