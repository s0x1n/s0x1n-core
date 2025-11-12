# s0x1n-inst Starter Template

Copy this structure to your `s0x1n-inst` repository.

## Directory Structure

```
s0x1n-inst/
├── flake.nix
├── flake.lock
├── .gitignore
├── .sops.yaml
├── secrets.yaml (encrypted)
├── hosts/
│   └── myhost/
│       ├── configuration.nix
│       └── hardware-configuration.nix
└── README.md
```

## File: flake.nix

```nix
{
  description = "s0x1n NixOS deployments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    s0x1n-core = {
      url = "github:s0x1n/s0x1n-core";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, s0x1n-core }:
    let
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/${hostname}/configuration.nix
        ];
        specialArgs = {
          foundation = s0x1n-core;
        };
      };
    in {
      nixosConfigurations = {
        myhost = mkHost "myhost";
        # Add more hosts here as needed
      };
    };
}
```

## File: .gitignore

```
# Nix
result
result-*
*.qcow2

# Secrets (unencrypted)
secrets/*.env
secrets/*.key
secrets/*.txt

# Keep encrypted secrets
!secrets.yaml

# Editor
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Hardware configs are often machine-specific
# Uncomment to not commit them:
# hosts/*/hardware-configuration.nix
```

## File: .sops.yaml

```yaml
# Get your age public key with:
# age-keygen -y /persist/var/lib/sops-nix/key.txt
# Or for YubiKey: age-plugin-yubikey --list

keys:
  - &admin age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
          - *admin
```

## File: secrets.yaml (template - encrypt with sops)

Before committing, run: `sops secrets.yaml`

```yaml
# User passwords (generate with: mkpasswd -m sha-512)
user-password: "$6$rounds=656000$..."

# WiFi passwords
wifi-home-psk: "your-wifi-password"
wifi-work-psk: "your-work-password"

# SSH keys (if needed)
# ssh-private-key: |
#   -----BEGIN OPENSSH PRIVATE KEY-----
#   ...
#   -----END OPENSSH PRIVATE KEY-----
```

## File: hosts/myhost/configuration.nix

```nix
{ config, pkgs, foundation, ... }:

let
  lib = foundation.lib;
  username = "myuser";
  
  # Storage configuration
  diskConfig = lib.foundation.storage.compose {
    device = "/dev/nvme0n1";  # Change to your device!
    
    filesystem = lib.foundation.storage.filesystems.btrfs {
      subvolumes = {
        root = { 
          mountpoint = "/"; 
          mountOptions = [ "compress=zstd" "noatime" ]; 
        };
        persist = { 
          mountpoint = "/persist"; 
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
      };
    };
    
    encryption = lib.foundation.storage.encryption.luksYubikey {
      method = "fido2";
      passwordFallback = true;
    };
    
    swapSize = "16G";
  };
  
  # Impermanence
  impermanenceConfig = lib.foundation.storage.impermanence {
    persistPath = "/persist";
    users.${username} = {};
  };
  
  # Boot (secure boot)
  bootConfig = lib.foundation.boot.lanzaboote {
    enable = true;
  };
  
  # Secrets
  secretsConfig = lib.foundation.secrets.sops {
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      user-password = { owner = username; };
      wifi-home-psk = {};
    };
  };
  
  # Users
  usersConfig = lib.foundation.users.declarative {
    users.${username} = {
      description = "My User";
      extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
      hashedPasswordFile = config.sops.secrets.user-password.path;
    };
  };
  
  # Network
  networkConfig = lib.foundation.network.networkManager {
    enable = true;
  };
  
  # Desktop (Niri)
  desktopConfig = lib.desktop.wayland.niri {
    enable = true;
    displayManager = "greetd";
    user = username;
  };

in {
  imports = [
    ./hardware-configuration.nix
    diskConfig
    impermanenceConfig.system
    bootConfig
    secretsConfig
    usersConfig
    networkConfig
    desktopConfig.system
  ];

  # System configuration
  networking.hostName = "myhost";
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    alacritty
    fuzzel
    firefox
  ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    fira-code
  ];

  # Home-manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    
    users.${username} = {
      imports = [ 
        impermanenceConfig.home.${username}
        desktopConfig.home.${username}
      ];
      
      home.stateVersion = "25.05";
      
      programs.niri.settings = {
        prefer-no-csd = true;
        
        input = {
          keyboard.xkb.layout = "us";
          touchpad = {
            tap = true;
            natural-scroll = true;
          };
        };
        
        binds = {
          "Mod+Return".action.spawn = "alacritty";
          "Mod+D".action.spawn = "fuzzel";
          "Mod+Q".action.close-window = {};
          "Mod+B".action.spawn = "firefox";
        };
      };
    };
  };

  system.stateVersion = "25.05";
}
```

## Installation Steps

1. **Setup secrets**:
   ```bash
   # Generate age key
   age-keygen -o age-key.txt
   
   # Get public key
   age-keygen -y age-key.txt
   
   # Update .sops.yaml with your public key
   # Edit and encrypt secrets
   sops secrets.yaml
   ```

2. **Generate hardware config** (on target machine from live USB):
   ```bash
   nixos-generate-config --root /mnt --show-hardware-config > hosts/myhost/hardware-configuration.nix
   ```

3. **Test build**:
   ```bash
   nix flake check
   nixos-rebuild build-vm --flake .#myhost
   ```

4. **Deploy**:
   ```bash
   # Format disks
   sudo nix run github:nix-community/disko -- --mode disko --flake .#myhost
   
   # Copy age key to /mnt/persist (before install!)
   sudo mkdir -p /mnt/persist/var/lib/sops-nix
   sudo cp age-key.txt /mnt/persist/var/lib/sops-nix/key.txt
   sudo chmod 600 /mnt/persist/var/lib/sops-nix/key.txt
   
   # Install
   sudo nixos-install --flake .#myhost
   
   # Reboot
   reboot
   
   # After first boot, enroll YubiKey
   sudo systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2
   
   # Setup secure boot
   sudo sbctl create-keys
   sudo sbctl enroll-keys --microsoft
   sudo nixos-rebuild boot
   # Reboot and enable Secure Boot in UEFI
   ```

## Tips

- Test in a VM first!
- Keep the age key safe - you'll need it to decrypt secrets
- YubiKey enrollment is optional but recommended
- Customize the niri config in home-manager
- Add more hosts by copying the structure
