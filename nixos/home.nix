{ config, pkgs, inputs, ... }:

let
  # Access the hyprland-plugins package set via the 'inputs' specialArg
  hyprPluginPkgs = inputs.hyprland-plugins.packages.${pkgs.system};
in
{
  home.username = "asdf";
  home.homeDirectory = "/home/asdf";
  home.stateVersion = "23.11"; # Set this to your actual NixOS version

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;

    plugins = [
      hyprPluginPkgs.hyprexpo
      hyprPluginPkgs.hyprbars
      # Add any other desired plugins here
    ];

    extraConfig = ''
      monitor=,preferred,auto,1
      exec-once = waybar
    '';
  };
  
  home.packages = with pkgs; [
    waybar
    alacritty
  ];
}
