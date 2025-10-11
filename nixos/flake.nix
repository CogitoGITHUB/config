{
  description = "NixOS flake with Home Manager, Hyprland, and plugins";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      # Define a minimal pkgs for the system to reference lib
      pkgs = import nixpkgs { inherit system; };

    in {
      nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
        inherit system;

        # Pass ALL inputs to modules via specialArgs
        specialArgs = { inherit inputs; }; 

        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          # Integrate Home Manager as a module
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            
            home-manager.users.asdf = {
              # Use the simplest relative path import:
              imports = [ ./home.nix ];
              
              # Ensure the home-manager module has the correct lib and pkgs
              # for its internal evaluations, matching our top-level pkgs.
              _module.args = {
                inherit (nixpkgs) lib;
                inherit pkgs;
                inherit inputs;
              };
            };
          }
        ];
      };
    };
}
