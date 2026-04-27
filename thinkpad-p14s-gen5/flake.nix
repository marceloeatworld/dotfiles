{
  description = "NixOS configuration for ThinkPad P14s Gen 5 (AMD) with Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland official flake.
    hyprland.url = "github:hyprwm/Hyprland";

    # Hermes Agent - AI agent with profiles, local LLM + API support
    hermes-agent.url = "github:NousResearch/hermes-agent";

    # Hyprshutdown - Graceful shutdown utility for Hyprland
    hyprshutdown.url = "github:hyprwm/hyprshutdown";

    # sops-nix - Encrypted secrets management (age)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, disko, hyprland, hermes-agent, hyprshutdown, sops-nix, ... } @ inputs:
    let
      system = "x86_64-linux";

      # Shared overlays (used by both pkgs and nixpkgs.overlays)
      sharedOverlays = [
        # Temporary Python package fix for the current nixos-unstable snapshot.
        # Keep this grouped so it is easy to drop once nixpkgs catches up.
        (final: prev: {
          pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
            (python-final: python-prev: {
              # Not in nixpkgs yet; used by the Waybar wallet script.
              embit = python-final.buildPythonPackage rec {
                pname = "embit";
                version = "0.8.0";
                pyproject = true;

                src = prev.fetchPypi {
                  inherit pname version;
                  hash = "sha256-i/SxAHPGdAA3DOUj+xbwNf51n2/dmHxXm9zCaNde13A=";
                };

                build-system = [
                  python-final.setuptools
                ];

                pythonImportsCheck = [ "embit" ];

                meta = {
                  description = "Minimal Bitcoin library for MicroPython and Python 3";
                  homepage = "https://embit.rocks/";
                  license = prev.lib.licenses.mit;
                };
              };

            })
          ];
        })
        # VS Code Latest - Always use the latest version from Microsoft
        # Update: overlays/vscode-latest.nix (version + sha256)
        (final: prev:
          let
            vscodeInfo = import ./overlays/vscode-latest.nix {
              inherit (prev) lib fetchurl vscode;
            };
          in
          {
            vscode = vscodeInfo;
            vscode-fhs = vscodeInfo.fhs;
          })
        # Claude Code Latest - Always use latest from npm (official Anthropic source)
        # Update: overlays/claude-code-latest.nix (version + hash)
        (final: prev: {
          claude-code = import ./overlays/claude-code-latest.nix {
            inherit (prev) lib fetchurl claude-code patchelf glibc stdenv;
          };
        })
        # llama.cpp Latest - Local LLM inference with ROCm + native optimizations
        # Update: overlays/llama-cpp-latest.nix (version + hash)
        (final: prev: {
          llama-cpp = import ./overlays/llama-cpp-latest.nix {
            inherit (prev) lib llama-cpp fetchFromGitHub;
          };
        })
        # OpenCode Latest - AI coding agent from prebuilt binary (Bun SEA)
        # Update: overlays/opencode-latest.nix (version + sha256)
        (final: prev: {
          opencode = import ./overlays/opencode-latest.nix {
            inherit (prev) lib fetchurl opencode patchelf glibc stdenv;
          };
        })
        # ForgeCode Latest - AI coding harness from prebuilt binary (musl static)
        # Update: overlays/forgecode-latest.nix (version + sha256)
        (final: prev: {
          forgecode = import ./overlays/forgecode-latest.nix {
            inherit (prev) lib fetchurl stdenv;
          };
        })
        # Codex Latest - OpenAI coding agent from prebuilt binary (musl static)
        # Update: overlays/codex-latest.nix (version + sha256)
        (final: prev: {
          codex = import ./overlays/codex-latest.nix {
            inherit (prev) lib fetchurl stdenv;
          };
        })
        # RunPod CLI - Built from source (Go), manages GPU workloads
        # Update: overlays/runpodctl-latest.nix (version + hash + vendorHash)
        (final: prev: {
          runpodctl = prev.callPackage ./overlays/runpodctl-latest.nix { };
        })
        # pnpm Latest - Fast Node package manager from prebuilt binary (musl static)
        # Update: overlays/pnpm-latest.nix (version + sha256)
        (final: prev: {
          pnpm = import ./overlays/pnpm-latest.nix {
            inherit (prev) lib fetchurl stdenv;
          };
        })
      ];

      # Common special args passed to all modules
      specialArgs = {
        inherit inputs;
      };
    in
    {
      # NixOS configuration
      nixosConfigurations.pop = nixpkgs.lib.nixosSystem {
        inherit specialArgs;

        modules = [
          # Configure nixpkgs for this system
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = sharedOverlays;
          }

          # Disko for declarative disk partitioning
          disko.nixosModules.disko
          ./hosts/thinkpad/disko-config.nix

          # Hardware configuration
          ./hosts/thinkpad/hardware-configuration.nix

          # Official ThinkPad P14s Gen 5 AMD hardware profile
          nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5

          # Main configuration
          ./hosts/thinkpad/configuration.nix

          # System modules
          ./modules/system/boot.nix
          ./modules/system/networking.nix
          ./modules/system/hyprland.nix
          ./modules/system/sound.nix
          ./modules/system/locale.nix
          ./modules/system/users.nix
          ./modules/system/security.nix
          ./modules/system/services.nix
          ./modules/system/llama-cpp.nix
          ./modules/system/virtualisation.nix
          ./modules/system/btrfs.nix
          ./modules/system/amd-optimizations.nix # AMD Ryzen 7 PRO 8840HS + Radeon 780M
          ./modules/system/steam.nix
          ./modules/system/fonts.nix # System-wide fonts (REQUIRED for Hyprland/Wayland)
          ./modules/system/vpn-dns-switch.nix # Automatic DNS switching for VPN (Quad9 ↔ Proton)
          ./modules/system/ddcutil.nix # DDC/CI support for external monitor brightness control
          ./modules/system/security-tools.nix # Security audit tools (nmap, wireshark, aircrack-ng, hashcat)
          ./modules/system/nh.nix # NH - Modern Nix Helper
          ./modules/system/performance.nix # Zram, ananicy-cpp, earlyoom, gamemode
          ./modules/system/hermes-agent.nix # Hermes Agent - AI agent with profiles

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.marcelo = import ./modules/home/home.nix;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupFileExtension = "backup"; # Auto-backup existing files
          }
        ];
      };
    };
}
