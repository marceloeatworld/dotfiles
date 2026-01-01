{
  description = "NixOS configuration for ThinkPad P14s Gen 5 (AMD) with Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-starship = {
      url = "github:catppuccin/starship";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, disko, ... } @ inputs:
    let
      system = "x86_64-linux";

      # Use unstable as default for latest software versions
      pkgs = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          # Fix proton-core bcrypt test failures (password >72 bytes incompatibility)
          (final: prev: {
            python3 = prev.python3.override {
              packageOverrides = pyfinal: pyprev: {
                proton-core = pyprev.proton-core.overridePythonAttrs (old: {
                  doCheck = false;
                  doInstallCheck = false;
                });
              };
            };
            python313 = prev.python313.override {
              packageOverrides = pyfinal: pyprev: {
                proton-core = pyprev.proton-core.overridePythonAttrs (old: {
                  doCheck = false;
                  doInstallCheck = false;
                });
              };
            };
          })
          # VS Code Latest - Always use the latest version from Microsoft
          # Update: overlays/vscode-latest.nix (version + sha256)
          (final: prev: {
            vscode = import ./overlays/vscode-latest.nix {
              inherit (prev) lib fetchurl vscode;
            };
          })
        ];
      };

      # Stable packages (for rare cases where stability is preferred)
      pkgs-stable = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Keep pkgs-unstable alias for backwards compatibility
      pkgs-unstable = pkgs;

      # Common special args passed to all modules
      specialArgs = {
        inherit inputs;
        inherit pkgs-unstable;
        inherit pkgs-stable;
      };
    in
    {
      # NixOS configuration
      nixosConfigurations.pop = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;

        modules = [
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
          ./modules/system/virtualisation.nix
          ./modules/system/btrfs.nix
          ./modules/system/amd-optimizations.nix  # AMD Ryzen 7 PRO 8840HS + Radeon 780M
          ./modules/system/steam.nix
          ./modules/system/fonts.nix  # System-wide fonts (REQUIRED for Hyprland/Wayland)
          ./modules/system/vpn-dns-switch.nix  # Automatic DNS switching for VPN (Quad9 ↔ Proton)
          ./modules/system/ddcutil.nix  # DDC/CI support for external monitor brightness control
          ./modules/system/security-tools.nix  # Security audit tools (nmap, wireshark, aircrack-ng, hashcat)
          ./modules/system/nh.nix  # NH - Modern Nix Helper
          ./modules/system/performance.nix  # Zram, ananicy-cpp, earlyoom, gamemode

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.marcelo = import ./modules/home/home.nix;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupFileExtension = "backup";  # Auto-backup existing files
          }
        ];
      };
    };
}
