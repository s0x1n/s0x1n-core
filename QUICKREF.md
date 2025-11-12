# Quick Reference

## Library Structure

```
foundation.lib.foundation.storage.compose        # Main disk config
foundation.lib.foundation.storage.filesystems    # btrfs, ext4
foundation.lib.foundation.storage.encryption     # luksPassword, luksYubikey
foundation.lib.foundation.storage.impermanence   # Ephemeral root

foundation.lib.foundation.boot                   # lanzaboote, systemdBoot
foundation.lib.foundation.secrets                # sops, yubikey age
foundation.lib.foundation.users                  # declarative users
foundation.lib.foundation.network                # networkManager, systemdNetworkd

foundation.lib.desktop.wayland                   # niri
```

## Common Patterns

### Minimal disk setup
```nix
lib.foundation.storage.compose {
  device = "/dev/vda";
  filesystem = lib.foundation.storage.filesystems.ext4 {};
}
```

### Full featured
```nix
lib.foundation.storage.compose {
  device = "/dev/nvme0n1";
  filesystem = lib.foundation.storage.filesystems.btrfs {
    subvolumes = { /* ... */ };
  };
  encryption = lib.foundation.storage.encryption.luksYubikey {};
  swapSize = "16G";
}
```

### Impermanence
```nix
lib.foundation.storage.impermanence {
  persistPath = "/persist";
  users.username = {};
}
```

### Users with sops
```nix
lib.foundation.users.declarative {
  users.username = {
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.user-password.path;
  };
}
```

### Niri desktop
```nix
lib.desktop.wayland.niri {
  user = "username";
  displayManager = "greetd";
}
```

## Post-Install Commands

### YubiKey LUKS enrollment
```bash
sudo systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2
```

### Secure boot setup
```bash
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
sudo nixos-rebuild boot
# Enable Secure Boot in UEFI
```

### Secrets management
```bash
# Generate age key
age-keygen -o key.txt

# Get public key
age-keygen -y key.txt

# Edit secrets
sops secrets.yaml
```

### System rebuild
```bash
# From deployment repo
sudo nixos-rebuild switch --flake ~/.config/nixos#hostname
```

## Device Paths

| Type | Device | Part 1 | Part 2 |
|------|--------|--------|--------|
| SATA | /dev/sda | sda1 | sda2 |
| NVMe | /dev/nvme0n1 | nvme0n1p1 | nvme0n1p2 |
| eMMC | /dev/mmcblk0 | mmcblk0p1 | mmcblk0p2 |
| VM   | /dev/vda | vda1 | vda2 |

## Default Persist Paths

System: `/nix`, `/var/log`, `/var/lib/{nixos,systemd,bluetooth}`, `/etc/{machine-id,ssh}`, `/root`

Home: Entire directory persists
