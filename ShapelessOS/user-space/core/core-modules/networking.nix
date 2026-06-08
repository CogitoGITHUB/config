{ config, pkgs, ... }:

{
  networking.hostName = "ShapelessOS";
  networking.networkmanager.enable = true;

  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [
    "--netfilter-mode=nodivert"
    "--accept-dns=false"
  ];
}
