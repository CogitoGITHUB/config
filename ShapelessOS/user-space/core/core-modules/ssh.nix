{ config, pkgs, ... }:

{
  services.openssh.enable = true;

  # Optional hardening later:
  # services.openssh.settings = {
  #   PasswordAuthentication = false;
  #   KbdInteractiveAuthentication = false;
  #   PermitRootLogin = "no";
  # };
}
