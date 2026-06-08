{ config, pkgs, lib, ... }:
{
  # Kernel sysctl parameters for performance and security
  # boot.kernel.sysctl = {
  #   # Network performance
  #   "net.core.default_qdisc" = "fq";
  #   "net.ipv4.tcp_congestion_control" = "bbr";
  #   "net.ipv4.tcp_fastopen" = 3;
    
  #   # File system
  #   "fs.inotify.max_user_watches" = 524288;
  #   "fs.file-max" = 2097152;
    
  #   # Virtual memory
  #   "vm.swappiness" = 10;
  #   "vm.vfs_cache_pressure" = 50;
  #   "vm.dirty_ratio" = 10;
  #   "vm.dirty_background_ratio" = 5;
    
  #   # Security
  #   "kernel.dmesg_restrict" = 1;
  #   "kernel.kptr_restrict" = 2;
  # };
}
