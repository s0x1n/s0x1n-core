{ lib }:

# Creates a btrfs filesystem configuration
# Returns a function that takes options and produces disko-compatible config
# Device will be provided by compose.nix
{ 
  label ? "nixos",
  subvolumes ? {
    root = {
      mountpoint = "/";
      mountOptions = [ "compress=zstd" "noatime" ];
    };
    home = {
      mountpoint = "/home";
      mountOptions = [ "compress=zstd" "noatime" ];
    };
    nix = {
      mountpoint = "/nix";
      mountOptions = [ "compress=zstd" "noatime" ];
    };
    snapshots = {
      mountpoint = "/.snapshots";
      mountOptions = [ "compress=zstd" "noatime" ];
    };
  },
  extraMountOptions ? [ ],
}:

let
  # Required subvolumes that must exist
  requiredSubvolumes = [ "nix" ];
  
  # Get list of mountpoints from subvolumes
  mountpoints = lib.mapAttrsToList (name: config: config.mountpoint) subvolumes;
  
  # Check if /nix mountpoint exists
  hasNix = lib.any (mp: mp == "/nix") mountpoints;
  
  # Validate required subvolumes
  validated = 
    if !hasNix then
      throw "btrfs configuration must include a subvolume mounted at /nix"
    else
      subvolumes;

  # Helper to build subvolume configuration
  mkSubvolume = name: config: {
    inherit name;
    mountpoint = config.mountpoint;
    mountOptions = config.mountOptions ++ extraMountOptions;
  };

  # Convert subvolumes attrset to list format disko expects
  subvolumeList = lib.mapAttrsToList mkSubvolume validated;

in {
  type = "btrfs";
  # device will be set by compose.nix
  extraArgs = [ "-L" label "-f" ];
  subvolumes = lib.listToAttrs (map (sv: {
    name = sv.name;
    value = {
      mountpoint = sv.mountpoint;
      mountOptions = sv.mountOptions;
    };
  }) subvolumeList);
}
