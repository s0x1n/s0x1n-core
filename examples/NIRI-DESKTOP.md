# Complete NixOS Configuration Example with Niri

This example shows a complete system configuration using the foundation library with:
- Btrfs + LUKS encryption (YubiKey + password)
- Impermanence (ephemeral root)
- Secure boot (Lanzaboote)
- sops-nix for secrets
- Declarative user management
- NetworkManager
- Niri Wayland compositor

## Configuration

```nix
{ config, pkgs, foundation, ... }:

let
  lib = foundation.lib;
  
  # User configuration
  username = "myuser";
  
  # Disk configuration with impermanence
  diskConfig = lib.foundation.storage.compose {
    device = "/dev/nvme0n1";
    
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
  
  # Impermanence configuration
  impermanenceConfig = lib.foundation.storage.impermanence {
    persistPath = "/persist";
    users.${username} = {};
  };
  
  # Boot configuration (secure boot)
  bootConfig = lib.foundation.boot.lanzaboote {
    enable = true;
  };
  
  # Secrets configuration
  secretsConfig = lib.foundation.secrets.sops {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      user-password = {
        owner = username;
      };
      wifi-home-psk = {};
    };
  };
  
  # User configuration
  usersConfig = lib.foundation.users.declarative {
    users.${username} = {
      description = "My User";
      extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
      hashedPasswordFile = config.sops.secrets.user-password.path;
      openssh.authorizedKeys = [
        "ssh-ed25519 AAAA... user@host"
      ];
    };
  };
  
  # Network configuration
  networkConfig = lib.foundation.network.networkManager {
    enable = true;
    networks.home = {
      ssid = "MyHomeNetwork";
      security = {
        keyMgmt = "wpa-psk";
        # Password from sops - handle this in NetworkManager config
      };
    };
  };
  
  # Desktop configuration (Niri)
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

  # Basic system configuration
  networking.hostName = "mynixos";
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Essential packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    
    # Terminal
    alacritty
    
    # Launcher
    fuzzel
    
    # Notifications
    mako
    
    # File manager
    nnn
    
    # Browser
    firefox
    
    # System tools
    htop
    git
  ];

  # Enable SSH
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
    fira-code-symbols
  ];

  # Home-manager integration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    
    users.${username} = {
      imports = [ 
        impermanenceConfig.home.${username}
        desktopConfig.home.${username}
      ];
      
      home.stateVersion = "25.05";
      
      # Customize niri configuration
      programs.niri.settings = {
        # Add your custom niri config here
        prefer-no-csd = true;
        
        input = {
          keyboard.xkb.layout = "us";
          touchpad = {
            tap = true;
            natural-scroll = true;
          };
        };
        
        binds = {
          # Your custom keybindings
          "Mod+Return".action.spawn = "alacritty";
          "Mod+D".action.spawn = "fuzzel";
          "Mod+Q".action.close-window = {};
        };
      };
      
      # Additional home packages
      home.packages = with pkgs; [
        # Add user-specific packages
      ];
    };
  };

  system.stateVersion = "25.05";
}
```

## Installation Steps

1. **Prepare secrets file** (`secrets.yaml`):
```bash
# Generate password hash
mkpasswd -m sha-512

# Create secrets file
sops secrets.yaml
# Add:
# user-password: "$6$..."
# wifi-home-psk: "your-wifi-password"
```

2. **Format and install**:
```bash
# Format disks with disko
sudo nix run github:nix-community/disko -- --mode disko --flake .#mynixos

# Install NixOS
sudo nixos-install --flake .#mynixos
```

3. **Post-install setup**:
```bash
# Reboot into new system
reboot

# Enroll YubiKey for LUKS
sudo systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2

# Setup secure boot keys
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft

# Rebuild to sign boot files
sudo nixos-rebuild boot --flake ~/.config/nixos#mynixos

# Reboot and enable Secure Boot in UEFI
reboot
```

## Customizing Niri

Edit your niri configuration in home-manager:

```nix
programs.niri.settings = {
  input = {
    keyboard.xkb = {
      layout = "us";
      options = "ctrl:nocaps";  # Caps Lock as Ctrl
    };
  };
  
  layout = {
    gaps = 16;
    struts.left = 64;  # Reserve space for a status bar
  };
  
  binds = {
    # Custom keybindings
    "Mod+B".action.spawn = "firefox";
    "Mod+E".action.spawn = "nautilus";
  };
};
```

## Next Steps

- Configure waybar or use niri's built-in bar
- Setup notification daemon (mako, dunst)
- Configure app-specific settings
- Add more desktop applications
