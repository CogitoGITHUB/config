{ config, pkgs, inputs, ... }:

let
  # Access the hyprland-plugins package set via the 'inputs' specialArg
  hyprPluginPkgs = inputs.hyprland-plugins.packages.${pkgs.system};
  
  # --- READ EXTERNAL CONFIG FILE ---
  # Reads the content of ~/.config/hypr/main.conf and makes it available here.
  externalHyprConfig = builtins.readFile ../hypr/main.conf;
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

    # Inject the entire contents of your external main.conf.
    # All keybinds, monitors, and exec-once commands should be in that file now.
    extraConfig = externalHyprConfig;
  };
}

