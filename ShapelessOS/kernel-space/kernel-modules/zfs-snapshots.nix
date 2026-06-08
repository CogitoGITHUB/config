{ config, pkgs, lib, ... }:
{
  # ZFS with automatic snapshots
  # NOTE: Only enable if you have ZFS filesystems
  
  # boot.supportedFilesystems = [ "zfs" ];
  # boot.zfs.forceImportRoot = false;
  
  # # ZFS services
  # services.zfs = {
  #   autoScrub = {
  #     enable = true;
  #     interval = "monthly";
  #   };
    
  #   autoSnapshot = {
  #     enable = false;  # Set to true if using ZFS
  #     frequent = 4;    # every 15 min, keep 4
  #     hourly = 24;     # keep 24 hours
  #     daily = 7;       # keep 7 days
  #     weekly = 4;      # keep 4 weeks  
  #     monthly = 12;    # keep 12 months
  #   };
    
  #   trim = {
  #     enable = true;
  #     interval = "weekly";
  #   };
  # };
  
  # ZFS kernel module parameters
 # boot.kernelParams = [ 
 #   # "zfs.zfs_arc_max=8589934592"  # Limit ARC to 8GB (adjust as needed)
 # ];
  
  # Sanoid for advanced snapshot management (alternative to zfs autoSnapshot)
  # services.sanoid = {
  #   enable = false;
  #   datasets = {
  #     "tank/home" = {
  #       useTemplate = [ "production" ];
  #     };
  #   };
  #   templates = {
  #     production = {
  #       frequently = 4;
  #       hourly = 24;
  #       daily = 7;
  #       monthly = 12;
  #       yearly = 2;
  #       autosnap = true;
  #       autoprune = true;
  #     };
  #   };
  # };
}
