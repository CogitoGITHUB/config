{ config, pkgs, lib, ... }:
{
  # # Kernel selection
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # # Kernel parameters
  # boot.kernelParams = [
  #   "quiet"
  #   "splash"
  #   "consoleblank=0"  # Disable screen blanking
  # ];
  
  # # Kernel modules to load
  # boot.kernelModules = [
  #   "tcp_bbr"    # Better TCP congestion control
  # ];
  
  # # Extra kernel modules
  # boot.extraModulePackages = [ ];
}
