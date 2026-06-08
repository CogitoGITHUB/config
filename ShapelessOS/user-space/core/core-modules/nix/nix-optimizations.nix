{ config, pkgs, lib, ... }:
{
  # ===========================================================================
  # NIX STORE OPTIMIZATION
  # ===========================================================================
  nix = {
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 14d";
    };

    settings = {
      auto-optimise-store = true;

      max-jobs = "auto";
      cores    = 0;
      sandbox  = true;

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    channel.enable = false;
  };

  # allowUnfree is not a nix.conf setting — it's handled at eval time via nixpkgs.config
  nixpkgs.config.allowUnfree = true;

  # ===========================================================================
  # TOOLS
  # ===========================================================================
  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nix-tree
    nix-du
    nix-top
    nix-diff
    nixpkgs-review
    cachix
    comma
  ];

  environment.variables = {
    NIX_BUILD_CORES = "0";
    TMPDIR          = "/tmp";
  };

  # ===========================================================================
  # DOCS
  # ===========================================================================
  documentation = {
    nixos.enable = true;
    man.enable   = true;
    info.enable  = true;
    doc.enable   = true;
  };
}
