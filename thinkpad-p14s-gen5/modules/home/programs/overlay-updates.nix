# Overlay-update shell functions (update-vscode, update-overlays, update, ...).
# Extracted from programs/shell.nix to keep the ~360-line block out of it.
# Prepended via lib.mkBefore so the functions are defined before the rest of the
# zsh init (which ends with the TTY1 Hyprland exec). They remain plain zsh
# functions, so behaviour is unchanged.
{ config, lib, ... }:
{
  programs.zsh.initContent = lib.mkBefore ''
      function __load_github_personal_access_token() {
        [[ -n "''${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]] && return 0

        local gh_token_file="${config.sops.secrets.github_personal_access_token.path}"
        if [[ -r "$gh_token_file" ]]; then
          export GITHUB_PERSONAL_ACCESS_TOKEN="$(< "$gh_token_file")"
        fi

        [[ -n "''${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]] && return 0

        local flake sops_file token
        flake=$(dotfiles-flake-dir 2>/dev/null) || return 0
        sops_file="$flake/sops/api-keys.yaml"
        if [[ -r "$sops_file" ]] && command -v sops >/dev/null 2>&1; then
          token=$(sops -d --extract '["github_personal_access_token"]' "$sops_file" 2>/dev/null || true)
          token="''${token//$'\n'/}"
          if [[ -n "$token" && "$token" != "null" ]]; then
            export GITHUB_PERSONAL_ACCESS_TOKEN="$token"
          fi
        fi
      }

      function __set_nix_github_access_token() {
        [[ -n "''${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]] || return 0
        export NIX_CONFIG="access-tokens = github.com=$GITHUB_PERSONAL_ACCESS_TOKEN"
      }

      function __with_nix_github_access_token() {
        (
          __load_github_personal_access_token
          __set_nix_github_access_token
          "$@"
        )
      }

      function overlay-path() {
        local flake
        flake=$(dotfiles-flake-dir) || return 1
        print -r -- "$flake/$1"
      }

      function update-binary-overlay() {
        local name="$1"
        local overlay_rel="$2"
        local latest_url="$3"
        local jq_filter="$4"
        local strip_prefix="$5"
        local download_template="$6"
        local hash_attr="$7"
        local prefetch_mode="''${8:-file}"
        local display_prefix="''${9:-}"

        local OVERLAY
        OVERLAY=$(overlay-path "$overlay_rel") || return 1

        echo ""
        echo "══════════════════════════════════════════"
        echo "  $name Update Check"
        echo "══════════════════════════════════════════"

        # Auth GitHub API with personal token to avoid 60 req/h rate limit
        __load_github_personal_access_token
        local -a curl_args=(-sL)
        if [[ "$latest_url" == *"api.github.com"* && -n "''${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
          curl_args+=(-H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN")
        fi

        local LATEST_RAW
        LATEST_RAW=$(curl "''${curl_args[@]}" "$latest_url" 2>/dev/null | jq -r "$jq_filter")
        local LATEST="$LATEST_RAW"
        if [[ -n "$strip_prefix" ]]; then
          LATEST="''${LATEST#$strip_prefix}"
        fi
        local CURRENT
        CURRENT=$(grep 'version = ' "$OVERLAY" | head -1 | sed 's/.*"\(.*\)".*/\1/')

        echo "Current: $display_prefix$CURRENT"
        echo "Latest:  $LATEST_RAW"

        if [[ -z "$LATEST" || "$LATEST" = "null" || "$LATEST_RAW" = "null" ]]; then
          echo "⚠ Could not fetch latest version (network error?)"
          return 0
        fi

        if [[ "$CURRENT" = "$LATEST" ]]; then
          echo "✓ Already up to date!"
          return 0
        fi

        local DOWNLOAD_URL="$download_template"
        DOWNLOAD_URL=$(printf '%s\n' "$DOWNLOAD_URL" | sed "s|{version}|$LATEST|g; s|{raw}|$LATEST_RAW|g")

        echo ""
        echo "Downloading $name $LATEST_RAW..."
        local HASH
        if [[ "$prefetch_mode" = "unpack" ]]; then
          HASH=$(nix-prefetch-url --unpack "$DOWNLOAD_URL")
        else
          HASH=$(nix-prefetch-url "$DOWNLOAD_URL")
        fi
        if [[ -z "$HASH" ]]; then
          echo "⚠ Failed to download $name $LATEST_RAW"
          return 1
        fi
        local SRI
        SRI=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

        sed -i "0,/version = \".*\"/{s/version = \".*\"/version = \"$LATEST\"/}" "$OVERLAY"
        sed -i "0,/$hash_attr = \".*\"/{s|$hash_attr = \".*\"|$hash_attr = \"$SRI\"|}" "$OVERLAY"

        echo "✓ Updated to $name $LATEST_RAW"
        return 2
      }

      function update-vscode() {
        update-binary-overlay \
          "VS Code" \
          "overlays/vscode-latest.nix" \
          "https://update.code.visualstudio.com/api/update/linux-x64/stable/latest" \
          ".productVersion" \
          "" \
          "https://update.code.visualstudio.com/{version}/linux-x64/stable" \
          "sha256"
      }

      function update-claude-code() {
        update-binary-overlay \
          "Claude Code" \
          "overlays/claude-code-latest.nix" \
          "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" \
          ".version" \
          "" \
          "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-{version}.tgz" \
          "sha256"
      }

      function update-opencode() {
        update-binary-overlay \
          "OpenCode" \
          "overlays/opencode-latest.nix" \
          "https://api.github.com/repos/anomalyco/opencode/releases/latest" \
          ".tag_name" \
          "v" \
          "https://github.com/anomalyco/opencode/releases/download/v{version}/opencode-linux-x64.tar.gz" \
          "sha256"
      }

      function update-forgecode() {
        update-binary-overlay \
          "ForgeCode" \
          "overlays/forgecode-latest.nix" \
          "https://api.github.com/repos/tailcallhq/forgecode/releases/latest" \
          ".tag_name" \
          "v" \
          "https://github.com/tailcallhq/forgecode/releases/download/v{version}/forge-x86_64-unknown-linux-musl" \
          "sha256"
      }

      function update-codex() {
        # Snapshot the overlay: update-binary-overlay seds version+sha256 in
        # before the companion prefetch runs, so a companion failure must
        # restore the file (NOT via git checkout - the overlay routinely sits
        # modified-but-uncommitted after a successful earlier update).
        local OVERLAY BACKUP
        OVERLAY=$(overlay-path "overlays/codex-latest.nix") || return 1
        BACKUP=$(mktemp)
        cp "$OVERLAY" "$BACKUP"
        update-binary-overlay \
          "Codex" \
          "overlays/codex-latest.nix" \
          "https://api.github.com/repos/openai/codex/releases/latest" \
          ".tag_name" \
          "rust-v" \
          "https://github.com/openai/codex/releases/download/rust-v{version}/codex-x86_64-unknown-linux-musl.tar.gz" \
          "sha256"
        local rc=$?
        if [[ $rc -eq 2 ]]; then
          # Also refresh the codex-code-mode-host companion asset (same version)
          local VERSION HASH SRI
          VERSION=$(grep 'version = ' "$OVERLAY" | head -1 | sed 's/.*"\(.*\)".*/\1/')
          HASH=$(nix-prefetch-url "https://github.com/openai/codex/releases/download/rust-v$VERSION/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz")
          if [[ -z "$HASH" ]]; then
            echo "⚠ Failed to download codex-code-mode-host $VERSION"
            cp "$BACKUP" "$OVERLAY"
            rm -f "$BACKUP"
            return 1
          fi
          SRI=$(nix hash convert --hash-algo sha256 --to sri "$HASH")
          sed -i "s|codeModeHostSha256 = \".*\"|codeModeHostSha256 = \"$SRI\"|" "$OVERLAY"
        fi
        rm -f "$BACKUP"
        return $rc
      }

      function update-runpodctl() {
        update-binary-overlay \
          "RunPod CLI" \
          "overlays/runpodctl-latest.nix" \
          "https://api.github.com/repos/runpod/runpodctl/releases/latest" \
          ".tag_name" \
          "v" \
          "https://github.com/runpod/runpodctl/releases/download/v{version}/runpodctl-linux-amd64" \
          "sha256"
      }

      # Update all agent skills (clone missing + pull existing)
      # Covers: Claude Code, ForgeCode, OpenCode skill caches + plugin marketplaces
      function update-skills() {
        echo ""
        echo "══════════════════════════════════════════"
        echo "  Agent Skills Update"
        echo "══════════════════════════════════════════"

        local updated=0
        local cloned=0
        local total=0

        # Unified skill cache — one clone per repo, distributed by ai-skills.nix on rebuild
        local skill_repos=(
          "$HOME/.cache/ai-skills/google|https://github.com/google/skills"
          "$HOME/.cache/ai-skills/cloudflare|https://github.com/cloudflare/skills"
          "$HOME/.cache/ai-skills/neon|https://github.com/neondatabase/agent-skills"
          "$HOME/.cache/ai-skills/pg-aiguide|https://github.com/timescale/pg-aiguide"
          "$HOME/.cache/ai-skills/runpod|https://github.com/runpod/skills"
          "$HOME/.cache/ai-skills/hyprland|https://github.com/marceloeatworld/hyprland-ai-skill"
          "$HOME/.cache/ai-skills/nixos|https://github.com/marceloeatworld/nixos-ai-skill"
          "$HOME/.cache/ai-skills/caveman|https://github.com/JuliusBrussee/caveman"
          "$HOME/.cache/ai-skills/fal-ai|https://github.com/fal-ai-community/skills"
          "$HOME/.cache/ai-skills/vercel|https://github.com/vercel-labs/agent-skills"
          "$HOME/.cache/ai-skills/design-md|https://github.com/google-labs-code/design.md"
          "$HOME/.cache/ai-skills/img2threejs|https://github.com/hoainho/img2threejs"
        )

        for entry in "''${skill_repos[@]}"; do
          local dir="''${entry%%|*}"
          local url="''${entry##*|}"
          local name=$(basename "$dir")
          local parent=$(basename "$(dirname "$dir")")
          total=$((total + 1))

          if [ ! -d "$dir/.git" ]; then
            echo "  Cloning: $parent/$name"
            mkdir -p "$(dirname "$dir")"
            git clone --quiet "$url" "$dir" 2>/dev/null || { echo "  Failed:  $parent/$name"; continue; }
            cloned=$((cloned + 1))
          else
            local before=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
            git -C "$dir" pull --ff-only --quiet 2>/dev/null || continue
            local after=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
            if [[ "$before" != "$after" ]]; then
              echo "  Updated: $parent/$name"
              updated=$((updated + 1))
            fi
          fi
        done

        # Also pull plugin marketplaces (no clone, managed by Claude Code)
        for dir in "$HOME/.claude/plugins/marketplaces/"*/; do
          [ -d "$dir/.git" ] || continue
          total=$((total + 1))
          local name=$(basename "$dir")
          local before=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
          git -C "$dir" pull --ff-only --quiet 2>/dev/null || continue
          local after=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
          if [[ "$before" != "$after" ]]; then
            echo "  Updated: marketplaces/$name"
            updated=$((updated + 1))
          fi
        done

        echo ""
        if [[ $cloned -gt 0 || $updated -gt 0 ]]; then
          [[ $cloned -gt 0 ]] && echo "  Cloned:  $cloned new repos"
          [[ $updated -gt 0 ]] && echo "  Updated: $updated repos"
          echo "  Total:   $total skill repos"
          return 2
        else
          echo "  All $total skill repos up to date."
          return 0
        fi
      }

      function update-pnpm() {
        # Pinned to v10.x: pnpm v11 (2026-04-28) broke nixpkgs's pnpmConfigHook.
        # Re-enable v11+ once nixpkgs catches up.
        # Uses npm tarball (JS bundle) so the wrapper runs on system Node 22.
        update-binary-overlay \
          "pnpm" \
          "overlays/pnpm-latest.nix" \
          "https://api.github.com/repos/pnpm/pnpm/releases?per_page=50" \
          "[.[] | select(.tag_name | startswith(\"v10.\"))][0].tag_name" \
          "v" \
          "https://registry.npmjs.org/pnpm/-/pnpm-{version}.tgz" \
          "sha256"
      }

      # Update quick overlays (VS Code + Claude Code + OpenCode + ForgeCode + Codex + RunPod + pnpm) + agent skills
      # Returns 0 if something was updated, 1 if nothing changed
      function update-overlays() {
        local changed=0
        update-vscode; [[ $? -eq 2 ]] && changed=1
        update-claude-code; [[ $? -eq 2 ]] && changed=1
        update-opencode; [[ $? -eq 2 ]] && changed=1
        update-forgecode; [[ $? -eq 2 ]] && changed=1
        update-codex; [[ $? -eq 2 ]] && changed=1
        update-runpodctl; [[ $? -eq 2 ]] && changed=1
        update-pnpm; [[ $? -eq 2 ]] && changed=1
        update-skills; [[ $? -eq 2 ]] && changed=1
        return $((1 - changed))
      }

      # Update overlays/skills, then rebuild only when something actually changed.
      function update-apps() {
        update-overlays
        local update_status=$?

        if [[ $update_status -eq 0 ]]; then
          local flake
          flake=$(dotfiles-flake-dir) || return 1
          (cd "$flake" && __with_nix_github_access_token nh os switch .)
          return $?
        fi

        if [[ $update_status -eq 1 ]]; then
          echo "Nothing to update."
          return 0
        fi

        return $update_status
      }

      function update() {
        local flake update_status
        flake=$(dotfiles-flake-dir) || return 1

        clean-dotfiles-result-links

        (
          cd "$flake" || exit 1
          # Auto-load GitHub token from sops in this subshell only (not the
          # parent), so update-overlays' curl calls and nix flake update both
          # authenticate to GitHub and dodge the 60 req/h anonymous rate limit.
          __load_github_personal_access_token
          __set_nix_github_access_token
          # Hyprland stays out of the daily update so it is not re-downloaded
          # every day. Use update-hyprland for the Hyprland stack.
          # nixpkgs-llama stays pinned (update-llama owns it).
          nix flake update disko home-manager jail-nix \
            nix-index-database nixos-hardware nixpkgs sops-nix &&
            { update-overlays || true; } &&
            nix flake check --no-build &&
            nix build --no-link --impure .#nixosConfigurations.pop.config.system.build.toplevel &&
            nh os switch .
        )
        update_status=$?

        clean-dotfiles-result-links
        return $update_status
      }

      # Update the Hyprland stack and rebuild. Kept out of the daily "update"
      # so Hyprland is not re-downloaded/rebuilt every day; run deliberately
      # (e.g. weekly). Binaries come from hyprland.cachix.org as long as the
      # flake keeps the packages unmodified.
      function update-hyprland() {
        local flake update_status
        flake=$(dotfiles-flake-dir) || return 1

        clean-dotfiles-result-links

        (
          cd "$flake" || exit 1
          __load_github_personal_access_token
          __set_nix_github_access_token
          nix flake update hyprland hyprshutdown &&
            nh os switch .
        )
        update_status=$?

        clean-dotfiles-result-links
        return $update_status
      }

      # Update llama.cpp and rebuild (long compile time)
      function update-llama() {
        update-binary-overlay \
          "llama.cpp" \
          "overlays/llama-cpp-latest.nix" \
          "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest" \
          ".tag_name" \
          "b" \
          "https://github.com/ggml-org/llama.cpp/archive/refs/tags/{raw}.tar.gz" \
          "hash" \
          "unpack" \
          "b"
        local update_status=$?
        [[ $update_status -eq 2 ]] || return $update_status

        local OVERLAY
        OVERLAY=$(overlay-path "overlays/llama-cpp-latest.nix") || return 1

        # Refresh npmDepsHash: the webui npm lockfile changes between releases,
        # so the prior hash is stale. Build once to let Nix report the correct
        # hash, then patch the overlay before the real rebuild.
        echo ""
        echo "Refreshing npmDepsHash for new release..."
        local flake
        flake=$(dotfiles-flake-dir) || return 1
        local NPM_HASH
        NPM_HASH=$(cd "$flake" && __with_nix_github_access_token nix build --no-link .#nixosConfigurations.pop.pkgs.llama-cpp 2>&1 \
          | awk '/got: */ {print $2; exit}')

        if [[ -n "$NPM_HASH" && "$NPM_HASH" == sha256-* ]]; then
          sed -i "s|npmDepsHash = \".*\"|npmDepsHash = \"$NPM_HASH\"|" "$OVERLAY"
          echo "✓ npmDepsHash updated to $NPM_HASH"
        else
          echo "✓ npmDepsHash already correct (or could not be refreshed)"
        fi

        echo ""
        echo "══════════════════════════════════════════"
        echo "  Rebuilding NixOS with llama.cpp..."
        echo "══════════════════════════════════════════"
        (cd "$flake" && __with_nix_github_access_token nh os switch .)
      }

      function update-llama-cpp() {
        update-llama "$@"
      }
  '';
}
