{ config, pkgs, ... }:
{
  # Console keymap
  console.keyMap = "dvorak";
  
  # Console font
  console.font = "Lat2-Terminus16";
  
  # Disable screen blanking (use kernel parameter instead)
  boot.kernelParams = [ "consoleblank=0" ];
}
