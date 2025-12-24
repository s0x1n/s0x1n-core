# Multi-Repository Setup Instructions

## Overview
You need to create two separate repository sessions and copy the flake.nix files to each.

---

## 1. Setup s0x1n/core (Public Framework)

### Steps:
1. Create a new session for the `s0x1n/core` repository
2. Create a file named `flake.nix` in the root with the following content:

```nix
{
  description = "Public NixOS configuration framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
  {
    mkSystem = { hostname, username, enableDocker ? false }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          {
            networking.hostName = hostname;

            users.users.${username} = {
              isNormalUser = true;
              extraGroups = [ "wheel" ] ++ (if enableDocker then [ "docker" ] else []);
            };

            home-manager.users.${username} = {
              home.stateVersion = "24.11";
              programs.git.enable = true;
            };

            services.docker.enable = enableDocker;
          }
        ];
      };
  };
}
```

3. Commit and push:
```bash
git add flake.nix
git commit -m "Add NixOS configuration framework"
git push
```

---

## 2. Setup s0x1n/deploy (Private Configuration)

### Steps:
1. Create a new session for the `s0x1n/deploy` repository
2. Create a file named `flake.nix` in the root with the following content:

```nix
{
  description = "My NixOS configurations";

  inputs.framework.url = "github:s0x1n/core";

  outputs = { framework, ... }:
  {
    nixosConfigurations = {
      desktop = framework.mkSystem {
        hostname = "my-desktop";
        username = "adrian";
        enableDocker = true;
      };

      laptop = framework.mkSystem {
        hostname = "my-laptop";
        username = "adrian";
        enableDocker = false;
      };
    };
  };
}
```

3. Commit and push:
```bash
git add flake.nix
git commit -m "Add NixOS configurations using framework"
git push
```

---

## 3. Testing the Setup

Once both repositories are pushed, test the configuration:

```bash
# In the s0x1n/deploy repository session
nix flake show
# Should display: desktop and laptop NixOS configurations

nix flake check
# Should validate the configuration

# Build a configuration (dry run)
nix build .#nixosConfigurations.desktop.config.system.build.toplevel --dry-run
```

---

## How It Works

1. **s0x1n/core** exports a `mkSystem` function that creates NixOS configurations
2. **s0x1n/deploy** imports the framework from GitHub and uses it to define systems
3. This pattern allows you to:
   - Keep the framework public and reusable
   - Keep your specific configurations private
   - Version control them independently
   - Share the framework across multiple machines/repos

---

## Updating the Framework

When you update the framework in s0x1n/core:

```bash
# In s0x1n/deploy repository
nix flake update framework
git add flake.lock
git commit -m "Update framework to latest version"
```
