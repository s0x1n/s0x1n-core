# Testing Checklist for s0x1n-core

Before deploying to a real system, verify these items:

## Pre-Push Checks

- [ ] All files committed to git
- [ ] `.gitignore` in place
- [ ] No sensitive data in repo (passwords, keys, etc.)
- [ ] Flake syntax valid: `nix flake check`
- [ ] Can evaluate lib: `nix eval .#lib --apply builtins.attrNames`

## Library Structure Tests

- [ ] Storage compose works: `nix eval .#lib.foundation.storage --apply builtins.attrNames`
- [ ] Boot configs available: `nix eval .#lib.foundation.boot --apply builtins.attrNames`
- [ ] Secrets module exists: `nix eval .#lib.foundation.secrets --apply builtins.attrNames`
- [ ] Users module exists: `nix eval .#lib.foundation.users --apply builtins.attrNames`
- [ ] Network module exists: `nix eval .#lib.foundation.network --apply builtins.attrNames`
- [ ] Desktop module exists: `nix eval .#lib.desktop --apply builtins.attrNames`

## Integration Tests (in s0x1n-inst)

### Test 1: Minimal VM Config
Create a minimal VM configuration to test basic functionality:

```nix
# hosts/test-vm/configuration.nix
{ config, pkgs, foundation, ... }:

let
  lib = foundation.lib;
  
  diskConfig = lib.foundation.storage.compose {
    device = "/dev/vda";
    filesystem = lib.foundation.storage.filesystems.ext4 {};
    # No encryption for test
  };
  
in {
  imports = [ diskConfig ];
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  networking.hostName = "test-vm";
  
  system.stateVersion = "25.05";
}
```

Test build: `nixos-rebuild build-vm --flake .#test-vm`

### Test 2: Full Stack (without hardware)
Test that all modules can be imported together without errors:

```bash
nix eval .#nixosConfigurations.myhost.config.system.build.toplevel --show-trace
```

### Test 3: Disko Dry Run
Test disko configuration generation:

```bash
nix run github:nix-community/disko -- --mode disko --dry-run --flake .#myhost
```

## Deployment Tests

### On Real Hardware

1. **Backup everything first!**

2. Test installation on non-critical system or VM:
   ```bash
   # Create bootable USB with NixOS
   # Boot from USB
   # Partition manually or use disko dry-run first
   sudo nix run github:nix-community/disko -- --mode disko --flake github:s0x1n/s0x1n-inst#myhost
   sudo nixos-install --flake github:s0x1n/s0x1n-inst#myhost
   ```

3. Post-install verification:
   - [ ] System boots
   - [ ] YubiKey enrollment works (if using)
   - [ ] Impermanence active (check `/` is ephemeral)
   - [ ] User can login
   - [ ] Network connectivity
   - [ ] Niri starts and is usable

## Common Issues to Watch For

1. **Device naming**: Ensure `/dev/vda` vs `/dev/nvme0n1` vs `/dev/sda` is correct
2. **YubiKey not present**: Have password fallback ready
3. **Secure boot**: Don't enable until keys are enrolled
4. **Home persistence**: Ensure home directory path is correct in impermanence config
5. **Niri dependencies**: Ensure terminal and launcher packages are installed

## Rollback Plan

If something goes wrong:
1. Boot from USB
2. Mount encrypted root if needed: `cryptsetup open /dev/vda2 cryptroot`
3. Mount filesystems: `mount /dev/mapper/cryptroot /mnt`
4. Fix configuration
5. `nixos-install --flake /path/to/fixed/config#myhost`

## Notes

- Test in a VM first!
- Keep a bootable USB handy
- Document any issues you find
- Push fixes to s0x1n-core as needed
