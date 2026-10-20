{
  description = "NixOS configuration for ThinkPad P14s Gen 5 (AMD) with Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned nixpkgs for llama-cpp build chain. Decouples llama.cpp from
    # `nix flake update` so the system rebuild never recompiles it. Bump
    # manually with `update-llama` when a fresh build is wanted.
    nixpkgs-llama.url = "github:NixOS/nixpkgs/549bd84d6279f9852cae6225e372cc67fb91a4c1";

    # Temporary pin for joplin-desktop only. nixos-unstable b4fd65b (2026-09-29)
    # carries a bad merge that reverted Joplin to 3.6.16 with stale yarn hashes
    # (fetchYarnBerryDeps: "unable to find missing hash for @esbuild/aix-ppc64").
    # This is the previous generation's nixpkgs (Joplin 3.7.18, cached). Drop
    # the input and the overlay once nixos-unstable contains nixpkgs commit
    # f3b35b92 (joplin-desktop 3.7.21, merged to master 2026-09-30).
    nixpkgs-joplin.url = "github:NixOS/nixpkgs/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f";

    # Tracks home-manager master. nixos-unstable has rolled to 26.11, so the
    # two currently match; the release check stays disabled in
    # modules/home/home.nix because master bumps its version first at every
    # release cycle and the skew warning would return.
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland official flake, pinned to master. Restored 2026-07-17: the
    # nixpkgs 0.55.4 release has a use-after-free on monitor replug (stale
    # window->monitor pointer, crash in damageMonitor/isMirror on click),
    # hit daily via the HDMI switch. Master carries the hardening fixes
    # (#14893, #15035, #15242, #15234); no release ships them yet.
    hyprland.url = "github:hyprwm/Hyprland";

    # No plugin flake input: hyprfocus (removed 2026-07-08, repeated SEGV in
    # libhyprfocus.so) and hyprexpo (SEGV on AMD iGPU) both crashed sessions.
    # Plugins stay out until upstream stabilizes.

    # jail.nix - bubblewrap sandbox engine behind the jailed-* agent wrappers.
    # Zero flake inputs. Replaces andersonjoseph/jailed-agents, which was a
    # thin layer over jail.nix and pulled the numtide stack (flake-utils,
    # llm-agents.nix, blueprint, bun2nix, treefmt-nix) into the lock.
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";

    # Hyprshutdown - Graceful shutdown utility for Hyprland
    hyprshutdown.url = "github:hyprwm/hyprshutdown";

    # sops-nix - Encrypted secrets management (age)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-index-database - prebuilt nix-index DB so `comma` / `,` and
    # command-not-found work without generating the index locally.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, nixpkgs-llama, nixpkgs-joplin, home-manager, nixos-hardware, disko, hyprland, hyprshutdown, sops-nix, ... } @ inputs:
    let
      system = "x86_64-linux";

      # Pinned nixpkgs snapshot used solely for llama-cpp build inputs.
      # Keeps the llama.cpp derivation hash stable across `nix flake update`.
      pkgsLlama = import nixpkgs-llama {
        inherit system;
        config.allowUnfree = true;
      };

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

              # Upstream breakage: androguard's test-only dependency pyqt5 fails
              # to build on Python 3.14. jadx -> quark-engine -> androguard.
              androguard = python-prev.androguard.overridePythonAttrs {
                doCheck = false;
              };
            })
          ];
        })
        # Upstream breakage: joplin-desktop 3.6.16 on nixos-unstable b4fd65b has
        # stale yarn missing-hashes (see the nixpkgs-joplin input comment).
        # Take the previous generation's 3.7.18 build instead.
        (final: prev: {
          joplin-desktop = (import nixpkgs-joplin {
            inherit system;
            config.allowUnfree = true;
          }).joplin-desktop;
        })
        # Upstream breakage: typescript-language-server 6.0.2 on nixos-unstable
        # 7fd4004 ships a stale pnpmDeps hash (pnpm_12 moved to 12.9.0 after the
        # hash was computed). Fixed by nixpkgs commit ac7b1aae (PR #572951);
        # same hash here. Drop once that commit lands on nixos-unstable.
        (final: prev: {
          typescript-language-server = prev.typescript-language-server.overrideAttrs (old: {
            pnpmDeps = old.pnpmDeps.override {
              hash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
            };
          });
        })
        # Upstream breakage: soapyuhd fails to compile against uhd 4.11
        # (UHDSoapyRxStream is abstract: get_stream_info is pure virtual).
        # Fix pending in nixpkgs PR #568744. Build SDR++ against the SoapySDR
        # plugin set without the USRP module; no USRP hardware here. Drop once
        # the PR lands on nixos-unstable.
        (final: prev: {
          sdrpp = prev.sdrpp.override {
            soapysdr-with-plugins = prev.soapysdr-with-plugins.override {
              soapyuhd = prev.emptyDirectory;
            };
          };
        })
        # Upstream breakage: patchelf 0.19.2 (nixpkgs PR #569010) corrupts the
        # prebuilt ARM toolchain; every binary segfaults in ld.so, so proxmark3
        # fails to build its firmware. Patch it with patchelf 0.15.2, as nixpkgs
        # PR #575979 does for CUDA. Drop once the revert (nixpkgs PR #574271)
        # lands on nixos-unstable.
        (final: prev: {
          gcc-arm-embedded-15 = prev.gcc-arm-embedded-15.overrideAttrs (old: {
            nativeBuildInputs = [
              (prev.patchelf.overrideAttrs (finalAttrs: _: {
                version = "0.15.2";
                src = prev.fetchurl {
                  url = "https://github.com/NixOS/patchelf/releases/download/${finalAttrs.version}/patchelf-${finalAttrs.version}.tar.bz2";
                  hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
                };
              }))
            ] ++ (old.nativeBuildInputs or [ ]);
          });
        })
        # VS Code Latest - Always use the latest version from Microsoft
        # Update: overlays/vscode-latest.nix (version + sha256)
        (final: prev:
          let
            vscodeInfo = import ./overlays/vscode-latest.nix {
              inherit (prev) fetchurl vscode libxtst libjpeg8 pipewire libei;
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
            inherit (prev) fetchurl claude-code patchelf glibc stdenv;
          };
        })
        # llama.cpp Latest - Local LLM inference with ROCm + native optimizations
        # Build inputs come from the pinned nixpkgs-llama snapshot so the
        # derivation hash stays stable when the main nixpkgs is bumped.
        # Update: overlays/llama-cpp-latest.nix (version + hash).
        (final: prev: {
          llama-cpp = import ./overlays/llama-cpp-latest.nix {
            inherit (pkgsLlama) llama-cpp fetchFromGitHub fetchNpmDeps;
          };
          # whisper-cpp links the system llama-cpp and requires the version
          # its nixpkgs revision ships (1.9.5 needs llama 0.6.0; the pinned
          # build reports 0.4.0-dev). Keep it on stock llama-cpp so whisper-cpp,
          # ffmpeg-full and kdenlive substitute from cache.nixos.org.
          whisper-cpp = prev.whisper-cpp.override { llama-cpp = prev.llama-cpp; };
        })
        # OpenCode Latest - AI coding agent from prebuilt binary (Bun SEA)
        # Update: overlays/opencode-latest.nix (version + sha256)
        (final: prev: {
          opencode = import ./overlays/opencode-latest.nix {
            inherit (prev) fetchurl opencode patchelf glibc stdenv;
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
        # Gemini CLI Latest - Google terminal agent from the upstream npm bundle
        # (nixpkgs lags and flags it as replaced by Antigravity CLI; paid API key still works)
        # Update: overlays/gemini-cli-latest.nix (version + sha256)
        (final: prev: {
          gemini-cli = prev.callPackage ./overlays/gemini-cli-latest.nix { };
        })
        # Yaru theme - removed from nixpkgs 2026-07-22 (gtk-engine-murrine
        # cleanup); restored locally without the GTK 2 murrine propagation.
        # All 7 config.theme presets use Yaru GTK/icon theme names.
        (final: prev: {
          yaru-theme = prev.callPackage ./overlays/yaru-theme.nix { };
        })
        # Pinned analysis and game-modding tools absent from nixpkgs.
        (final: prev: {
          siglens = prev.callPackage ./overlays/siglens.nix { };
          universal-modder = prev.callPackage ./overlays/universal-modder.nix { };
          rea = prev.callPackage ./overlays/rea.nix { };
        })
        # RunPod CLI - Prebuilt static Go binary, manages GPU workloads
        # Update: overlays/runpodctl-latest.nix (version + sha256)
        (final: prev: {
          runpodctl = prev.callPackage ./overlays/runpodctl-latest.nix { };
        })
        # BytePlus Ark CLI - Prebuilt static Go binary, ModelArk from the terminal
        # Update: overlays/arkcli-latest.nix (version + sha256)
        (final: prev: {
          arkcli = prev.callPackage ./overlays/arkcli-latest.nix { };
        })
        # pnpm Latest - Fast Node package manager from the npm tarball, wrapped
        # around system nodejs-slim_22 so process.version matches the host Node.
        # Update: overlays/pnpm-latest.nix (version + sha256)
        # Pinned to v10.x; v11 broke nixpkgs pnpmConfigHook (see overlay header).
        (final: prev: {
          pnpm = import ./overlays/pnpm-latest.nix {
            inherit (prev) lib fetchurl stdenv nodejs-slim_22 makeWrapper;
          };
        })
        # Waybar - pinned to master commit with Lua-protocol dispatch fix.
        # Required because Hyprland 0.55+ Lua mode broke the legacy IPC
        # dispatch syntax used by waybar 0.15.0's hyprland/workspaces clicks.
        # Built from the pinned nixpkgs-llama snapshot (like llama-cpp) so a
        # daily nixpkgs bump no longer recompiles Waybar from source; it only
        # rebuilds when the pin or nixpkgs-llama moves (update-llama).
        # Update: overlays/waybar-latest.nix (rev + hash)
        (final: prev: {
          waybar = import ./overlays/waybar-latest.nix {
            inherit (pkgsLlama) waybar fetchFromGitHub;
          };
        })
      ];

      # Common special args passed to all modules
      hyprlandPackages =
        let
          # Unmodified packages from the Hyprland flake. Any override here
          # changes the derivation hash and defeats hyprland.cachix.org,
          # forcing Hyprland + portal + guiutils to recompile from source on
          # every flake update. Keep these stock so binaries substitute.
          hyprland = inputs.hyprland.packages.${system}.hyprland;

          xdg-desktop-portal-hyprland = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
        in
        {
          inherit
            hyprland
            xdg-desktop-portal-hyprland
            ;
        };

      specialArgs = {
        inherit inputs hyprlandPackages;
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
            nixpkgs.config.android_sdk.accept_license = true;
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
          ./modules/system/postgresql.nix # Local PostgreSQL 18 for Medusa development
          ./modules/system/virtualisation.nix
          ./modules/system/btrfs.nix
          ./modules/system/amd-optimizations.nix # AMD Ryzen 7 PRO 8840HS + Radeon 780M
          ./modules/system/fonts.nix # System-wide fonts (REQUIRED for Hyprland/Wayland)
          ./modules/system/vpn-dns-switch.nix # Automatic DNS switching (dnscrypt-proxy <-> Proton VPN) + captive portal
          ./modules/system/ddcutil.nix # DDC/CI support for external monitor brightness control
          ./modules/system/sunxi-fel.nix # Allwinner FEL USB access for sunxi-fel without sudo (PocketCHIP)
          ./modules/system/smartcard.nix # pcscd for the Cartao de Cidadao USB reader
          ./modules/system/scanner.nix # SANE support for the Canon CanoScan LiDE 400
          ./modules/system/security-tools.nix # Security audit tools (nmap, wireshark, aircrack-ng, hashcat)
          ./modules/system/nh.nix # NH - Modern Nix Helper
          ./modules/system/performance.nix # Zram, ananicy-cpp, earlyoom, gamemode

          # Home Manager
          home-manager.nixosModules.home-manager
          ({ pkgs, ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.marcelo = import ./modules/home/home.nix;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupCommand = pkgs.writeShellScript "home-manager-backup-existing-file" ''
              set -eu

              if [ "$#" -eq 0 ]; then
                exit 0
              fi

              target="$1"
              stamp="$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
              backup="$target.hm-backup-$stamp"
              n=0

              while [ -e "$backup" ]; do
                n=$((n + 1))
                backup="$target.hm-backup-$stamp-$n"
              done

              ${pkgs.coreutils}/bin/mv "$target" "$backup"
              echo "Backed up $target to $backup" >&2
            '';
          })
        ];
      };
    };
}
