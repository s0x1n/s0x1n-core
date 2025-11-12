{ lib, diskoLib, impermanenceModule, homeManagerModule }:

{
  # Filesystem builders
  filesystems = {
    btrfs = import ./filesystems/btrfs.nix { inherit lib; };
    ext4 = import ./filesystems/ext4.nix { inherit lib; };
    zfs = import ./filesystems/zfs.nix { inherit lib; };
  };

  # Encryption builders
  encryption = {
    lukPassword = import ./encryption/luks-password.nix { inherit lib; };
    luksYubikey = import ./encryption/luks-yubikey.nix { inherit lib; };
  };

  # Common partition layouts
  layouts = import ./layouts { inherit lib; };

  # Impermanence configuration builder
  impermanence = import ./impermanence { 
    inherit lib impermanenceModule homeManagerModule; 
  };

  # Main composer function that combines everything
  compose = import ./compose.nix {
    inherit lib diskoLib;
    filesystems = {
      btrfs = import ./filesystems/btrfs.nix { inherit lib; };
      ext4 = import ./filesystems/ext4.nix { inherit lib; };
      zfs = import ./filesystems/zfs.nix { inherit lib; };
    };
    encryption = {
      luksPassword = import ./encryption/luks-password.nix { inherit lib; };
      luksYubikey = import ./encryption/luks-yubikey.nix { inherit lib; };
    };
  };
}
