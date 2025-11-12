# s0x1n-core

A modular, functional NixOS configuration library focused on immutable day-1 components. Build reproducible, secure NixOS systems with declarative disk configuration, encryption, impermanence, and desktop environments.

## Philosophy

- **Single source of truth**: Specify configuration once, derive everything else
- **Functional composition**: Build configs by calling pure functions
- **Day-1 immutability**: Get storage, encryption, boot, and core system right from the start
- **DRY and modular**: Reusable components across all your systems
- **Type-safe configuration**: Let Nix catch errors before deployment

## Quick Start

### In your flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    s0x1n-core = {
      url = "github:s0x1n/s0x1n-core";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### Minimal example

```nix
{ foundation, ... }:

let
  lib = foundation.lib;
in {
  imports = [
    (lib.foundation.storage.compose {
      device = "/dev/nvme0n1";
      filesystem = lib.foundation.storage.filesystems.btrfs {};
      encryption = lib.foundation.storage.encryption.luksYubikey {};
    })
  ];
}
```

## Features

### Foundation Layer (Day-1 Immutable)

#### 🗄️ Storage
- **Filesystems**: btrfs (with subvolumes), ext4, zfs (coming soon)
- **Encryption**: LUKS2 with password and/or YubiKey (FIDO2)
- **Smart partitioning**: Handles all device types (NVMe, SATA, eMMC, virtio)
- **Impermanence**: Ephemeral root with declarative persistence

#### 🔐 Boot
- **Secure boot**: lanzaboote integration for UEFI Secure Boot
- **Standard boot**: systemd-boot configuration
- **Automatic signing**: Boot files signed automatically

#### 🔑 Secrets
- **sops-nix**: Age-encrypted secrets management
- **YubiKey integration**: Use YubiKey PIV for age keys
- **Declarative secrets**: Secrets as code with encryption

#### 👥 Users
- **Declarative users**: All users managed in configuration
- **sops integration**: Passwords from encrypted secrets
- **SSH keys**: Declarative authorized keys

#### 🌐 Network
- **NetworkManager**: Imperative (nmtui) + declarative networks
- **systemd-networkd**: Fully declarative alternative
- **sops integration**: Encrypted WiFi passwords

### Desktop Layer

#### 🖥️ Wayland Compositors
- **Niri**: Scrollable-tiling compositor with full home-manager integration
- More compositors coming soon (Hyprland, Sway, etc.)

## Architecture

```
lib/
├── foundation/              # Day-1 immutable components
│   ├── storage/            # Disko, filesystems, encryption, impermanence
│   ├── boot/               # Lanzaboote, systemd-boot
│   ├── secrets/            # sops-nix, YubiKey age
│   ├── users/              # Declarative user management
│   └── network/            # NetworkManager, systemd-networkd
└── desktop/                # Desktop environments
    └── wayland/            # Wayland compositors (niri, etc.)
```

## Device Support

The library automatically handles partition naming for all device types:

| Device Type | Root Device | Partition 1 | Partition 2 |
|-------------|-------------|-------------|-------------|
| SATA/SCSI   | `/dev/sda`  | `/dev/sda1` | `/dev/sda2` |
| VirtIO      | `/dev/vda`  | `/dev/vda1` | `/dev/vda2` |
| NVMe        | `/dev/nvme0n1` | `/dev/nvme0n1p1` | `/dev/nvme0n1p2` |
| eMMC        | `/dev/mmcblk0` | `/dev/mmcblk0p1` | `/dev/mmcblk0p2` |

**You specify the device once** - everything else is handled automatically!

## Usage Examples

### Complete System with Niri Desktop

```nix
{ config, pkgs, foundation, ... }:

let
  lib = foundation.lib;
  username = "myuser";
  
  # All foundation components
  diskConfig = lib.foundation.storage.compose {
    device = "/dev/nvme0n1";
    filesystem = lib.foundation.storage.filesystems.btrfs {
      subvolumes = {
        root = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
        persist = { mountpoint = "/persist"; mountOptions = [ "compress=zstd" "noatime" ]; };
        nix = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
      };
    };
    encryption = lib.foundation.storage.encryption.luksYubikey {
      method = "fido2";
      passwordFallback = true;
    };
  };
  
  impermanenceConfig = lib.foundation.storage.impermanence {
    persistPath = "/persist";
    users.${username} = {};
  };
  
  bootConfig = lib.foundation.boot.lanzaboote {};
  secretsConfig = lib.foundation.secrets.sops {
    defaultSopsFile = ./secrets.yaml;
    secrets.user-password = { owner = username; };
  };
  
  usersConfig = lib.foundation.users.declarative {
    users.${username} = {
      extraGroups = [ "wheel" "networkmanager" ];
      hashedPasswordFile = config.sops.secrets.user-password.path;
    };
  };
  
  networkConfig = lib.foundation.network.networkManager {};
  desktopConfig = lib.desktop.wayland.niri { user = username; };

in {
  imports = [
    diskConfig
    impermanenceConfig.system
    bootConfig
    secretsConfig
    usersConfig
    networkConfig
    desktopConfig.system
  ];
  
  home-manager.users.${username}.imports = [ 
    impermanenceConfig.home.${username}
    desktopConfig.home.${username}
  ];
}
```

See [examples/](./examples/) for more detailed configurations.

## Documentation

- [TESTING.md](./TESTING.md) - Testing checklist and procedures
- [examples/DEPLOYMENT.md](./examples/DEPLOYMENT.md) - Basic deployment guide
- [examples/NIRI-DESKTOP.md](./examples/NIRI-DESKTOP.md) - Complete niri desktop setup
- [examples/DEPLOYMENT-REPO-TEMPLATE.md](./examples/DEPLOYMENT-REPO-TEMPLATE.md) - Starter template for deployment repo

## Integrated Flakes

- [disko](https://github.com/nix-community/disko) - Declarative disk partitioning
- [impermanence](https://github.com/nix-community/impermanence) - Ephemeral root filesystem
- [home-manager](https://github.com/nix-community/home-manager) - User environment management
- [lanzaboote](https://github.com/nix-community/lanzaboote) - Secure boot with systemd-boot
- [sops-nix](https://github.com/Mic92/sops-nix) - Secrets management with age
- [niri-flake](https://github.com/sodiboo/niri-flake) - Niri Wayland compositor

## Default Persistence Paths

System-level paths that persist by default:
- `/nix` - Nix store
- `/var/log` - System logs (for debugging)
- `/var/lib/nixos` - NixOS state
- `/var/lib/systemd` - systemd state
- `/var/lib/bluetooth` - Paired Bluetooth devices
- `/etc/machine-id` - System identity
- `/etc/ssh` - SSH host keys
- `/root` - Root user home

User home directories persist entirely by default.

## Contributing

Issues and PRs welcome at [s0x1n/s0x1n-core](https://github.com/s0x1n/s0x1n-core)

## License

MIT
