{ config, pkgs, wrappers, ... }:
{
  home.username = "aoeu";
  home.homeDirectory = "/home/aoeu";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

  # Example: wrap mpv with config and scripts
  # home.packages = [
  #   (wrappers.wrapperModules.mpv.apply {
  #     inherit pkgs;
  #     scripts = [ pkgs.mpvScripts.mpris ];
  #     "mpv.conf".content = ''
  #       vo=gpu
  #       hwdec=auto
  #     '';
  #     "mpv.input".content = ''
  #       WHEEL_UP seek 10
  #       WHEEL_DOWN seek -10
  #     '';
  #   }).wrapper
  # ];
}
