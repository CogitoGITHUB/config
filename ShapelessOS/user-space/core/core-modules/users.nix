{ config, pkgs, ... }:
{
  users.users.aoeu = {
    isNormalUser = true;
    description = "aoeu";
    extraGroups = [ "uinput" "seat" "video" "render" "networkmanager" "wheel" "docker" ];
    shell = pkgs.nushell;
    password = "aoeu";
  };
  
  users.groups.uinput = {};
}
