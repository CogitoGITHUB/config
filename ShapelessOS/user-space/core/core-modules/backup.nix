{ config, pkgs, ... }:

{
  # Core backup tools
  environment.systemPackages = with pkgs; [
    restic
    borgbackup
    rclone
    rsync
    duplicity
  ];

  # Optional: scheduled snapshot system (example pattern)
  # services.restic.backups.home = {
  #   initialize = true;
  #   passwordFile = "/var/lib/restic/pass";
  #   repository = "/backup/restic/home";
  #   paths = [ "/home" ];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #   };
  # };

  # Optional: borg pattern
  # services.borgbackup.jobs.home = {
  #   paths = [ "/home" ];
  #   repo = "/backup/borg/home";
  #   compression = "zstd";
  #   startAt = "daily";
  # };
}
