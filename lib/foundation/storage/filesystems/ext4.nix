{ lib }:

# Creates an ext4 filesystem configuration
# Returns a function that takes options and produces disko-compatible config
# Device will be provided by compose.nix
{
  label ? "nixos",
  mountpoint ? "/",
  mountOptions ? [ "noatime" "errors=remount-ro" ],
  extraFormatArgs ? [ ],
}:

{
  type = "ext4";
  inherit mountpoint;
  # device will be set by compose.nix
  
  # Format options for ext4
  extraArgs = [ "-L" label "-F" ] ++ extraFormatArgs;
  
  # Mount options
  mountOptions = mountOptions;
}
