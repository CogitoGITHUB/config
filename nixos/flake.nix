{
  description = "A NixOS configuration flake.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

   outputs = { self, nixpkgs,  ... }@inputs: {
    nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
      ];
    };
  };
}
