{ lib, diskoLib, filesystems, encryption }:

# Main composer that creates a complete disko configuration
# Combines filesystem, encryption, partition layout, and boot configuration
# Takes the root device ONCE and handles all partition naming internally
{
  device,  # Root device: /dev/vda, /dev/sda, /dev/nvme0n1, etc.
  filesystem,  # Filesystem config from filesystems.btrfs {} or filesystems.ext4 {}
  encryption ? null,  # Optional: encryption config from encryption.luksPassword {} or encryption.luksYubikey {}
  bootSize ? "512M",  # EFI boot partition size
  swapSize ? null,  # Optional: "8G" or null for no swap
}:

let
  # Helper to generate correct partition names for different device types
  # Examples:
  #   /dev/sda    -> /dev/sda1, /dev/sda2
  #   /dev/vda    -> /dev/vda1, /dev/vda2
  #   /dev/nvme0n1 -> /dev/nvme0n1p1, /dev/nvme0n1p2
  #   /dev/mmcblk0 -> /dev/mmcblk0p1, /dev/mmcblk0p2
  mkPartitionName = device: partNum:
    let
      needsP = lib.hasInfix "nvme" device || lib.hasInfix "mmcblk" device;
      separator = if needsP then "p" else "";
    in
      "${device}${separator}${toString partNum}";
  
  # Partition paths
  bootPartition = mkPartitionName device 1;
  rootPartition = mkPartitionName device 2;
  swapPartition = if swapSize != null then mkPartitionName device 3 else null;
  
  # Determine if we're using encryption
  isEncrypted = encryption != null;
  
  # Build encryption config with correct device
  encryptionConfig = 
    if isEncrypted then
      encryption // { device = rootPartition; }
    else
      null;
  
  # The device that the filesystem will be on
  # If encrypted: /dev/mapper/cryptroot (or custom name)
  # If not: the root partition directly
  filesystemDevice = 
    if isEncrypted then
      "/dev/mapper/${encryptionConfig.name}"
    else
      rootPartition;
  
  # Build the filesystem config with the correct device
  fsConfig = filesystem // { device = filesystemDevice; };
  
  # Build partition table
  partitions = {
    boot = {
      size = bootSize;
      type = "EF00";  # EFI System Partition
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "defaults" "umask=0077" ];
      };
    };
    
    root = {
      size = "100%";  # Use remaining space
      content = 
        if isEncrypted then
          encryptionConfig // {
            content = fsConfig;
          }
        else
          fsConfig;
    };
  } // lib.optionalAttrs (swapSize != null) {
    swap = {
      size = swapSize;
      content = {
        type = "swap";
        randomEncryption = isEncrypted;  # Encrypt swap if root is encrypted
      };
    };
  };

in {
  disko.devices = {
    disk.main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = partitions;
      };
    };
  };
}
