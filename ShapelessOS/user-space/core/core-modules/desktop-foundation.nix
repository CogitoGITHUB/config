{ config, pkgs, inputs, ... }:
{
  # Portal support for Wayland
  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
  ];
  
  # Graphics support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  # Seat management
  services.seatd.enable = true;
  
  # Wayland Compositor (Scroll)
  programs.scroll = {
    enable = true;
    package = inputs.scroll-flake.packages.${pkgs.stdenv.hostPlatform.system}.scroll-git;
    extraSessionCommands = ''
      export QT_QPA_PLATFORM="wayland;xcb"
      export GDK_BACKEND="wayland,x11"
      export SDL_VIDEODRIVER=wayland
      export CLUTTER_BACKEND=wayland
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
    '';
  };
  
  # Desktop Shell
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = false;
    systemd.restartIfChanged = false;
    quickshell.package = pkgs.quickshell;
    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
  };
}