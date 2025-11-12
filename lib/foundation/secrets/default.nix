{ lib, sopsModule }:

{
  # sops-nix configuration builder
  sops = import ./sops.nix { inherit lib sopsModule; };
  
  # YubiKey age key helper
  yubikey = import ./yubikey-age.nix { inherit lib; };
}
