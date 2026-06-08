{ config, pkgs, ... }:

{
  # Enable power management services
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}