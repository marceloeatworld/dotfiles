# /etc/nixos/flake.nix
{
  inputs = {
    # NOTE: Replace "nixos-23.11" with that which is in system.stateVersion of
    # configuration.nix. You can also use latter versions if you wish to
    # upgrade.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";    
    
    nur.url = "github:nix-community/NUR";

    hypr-contrib.url = "github:hyprwm/contrib";

 
      
hyprpicker.url = "github:hyprwm/hyprpicker";
  
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
  
    nix-gaming.url = "github:fufexan/nix-gaming";
  
    hyprland = {
      url = "github:hyprwm/Hyprland";
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
  outputs = inputs@{ self, nixpkgs, disko, home-manager, nur, ... }: 


let
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  lib = nixpkgs.lib;
in
{
    # NOTE: 'nixos' is the default hostname set by the installer
    nixosConfigurations.cute = nixpkgs.lib.nixosSystem {
      # NOTE: Change this to aarch64-linux if you are on ARM
  #    system = "x86_64-linux";
      modules = [ 
        ./configuration.nix 
        disko.nixosModules.disko
        
	./user.nix
	./coding.nix
	./hardware.nix
	./services.nix
	./network.nix
	./bootloader.nix
	./sound.nix
	./xserver.nix
	./wayland.nix
	./system.nix
	./security-services.nix
        ./virtualisation.nix
  	./steam.nix
	nur.nixosModules.nur
	
        home-manager.nixosModules.home-manager
	{
        home-manager.useGlobalPkgs = true;
	home-manager.useUserPackages = true;
	home-manager.users.marcelo = import ./home.nix;


        }
	
      ];
    specialArgs = { inherit inputs; };
    };
  };
}
