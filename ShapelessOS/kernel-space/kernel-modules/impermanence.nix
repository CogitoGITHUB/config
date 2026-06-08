{ config, pkgs, lib, ... }:
{
  # Impermanence - wipe root on every boot, keep only specific directories
  # Requires BTRFS subvolumes or similar setup
  
  # NOTE: This is a template - you need to adjust for your filesystem setup
  # Uncomment and configure after setting up BTRFS subvolumes
  
  # boot.initrd.postDeviceCommands = lib.mkAfter ''
  #   mkdir /btrfs_tmp
  #   mount /dev/disk/by-label/nixos /btrfs_tmp
  #   if [[ -e /btrfs_tmp/root ]]; then
  #       mkdir -p /btrfs_tmp/old_roots
  #       timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
  #       mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
  #   fi
  #   
  #   delete_subvolume_recursively() {
  #       IFS=$'\n'
  #       for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
  #           delete_subvolume_recursively "/btrfs_tmp/$i"
  #       done
  #       btrfs subvolume delete "$1"
  #   }
  #   
  #   for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
  #       delete_subvolume_recursively "$i"
  #   done
  #   
  #   btrfs subvolume create /btrfs_tmp/root
  #   umount /btrfs_tmp
  # '';
  
  # Persist important directories
  # environment.persistence."/persist" = {
  #   enable = false;  # Set to true after setting up /persist partition
  #   hideMounts = true;
  #   directories = [
  #     "/var/log"
  #     "/var/lib/nixos"
  #     "/var/lib/systemd/coredump"
  #     "/etc/nixos"
  #     "/var/lib/docker"
  #     "/var/lib/ollama"
  #   ];
  #   files = [
  #     "/etc/machine-id"
  #     "/etc/ssh/ssh_host_ed25519_key"
  #     "/etc/ssh/ssh_host_ed25519_key.pub"
  #     "/etc/ssh/ssh_host_rsa_key"
  #     "/etc/ssh/ssh_host_rsa_key.pub"
  #   ];
  # };
  
  # User persistence in home-manager config
  # home.persistence."/persist/home/aoeu" = {
  #   directories = [
  #     "Downloads"
  #     "Documents"
  #     ".config/ShapelessOS"
  #     ".local/share"
  #   ];
  # };
}
