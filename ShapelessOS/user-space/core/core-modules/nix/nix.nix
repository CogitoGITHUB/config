{ config, pkgs, ... }:

{
  # Enable flakes + new CLI
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Allow unfree software
  nixpkgs.config.allowUnfree = true;

  # System compatibility boundary
  system.stateVersion = "25.05";
}
