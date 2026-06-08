{ config, pkgs, lib, ... }:
{
  # ===========================================================================
  # AUTO LOGIN
  # ===========================================================================

  services.getty.autologinUser = lib.mkDefault "aoeu";

  # Lid switch — use the new option paths that NixOS expects
  services.logind.settings.Login = {
    HandleLidSwitch         = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked   = "ignore";
  };
}
