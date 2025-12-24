# NixOS Configuration Framework Test

This directory contains a test setup for a multi-repository Nix flake configuration framework.

## Structure

```
s0x1n-core/
├── test-pub/          # Public framework repository
│   └── flake.nix      # Provides mkSystem function
└── test-priv/         # Private configuration repository
    └── flake.nix      # Uses framework to define systems
```

## Concept

This demonstrates a pattern where:
- **test-pub** is a public/shared repository containing a reusable NixOS configuration framework
- **test-priv** is a private repository that imports the framework and defines specific system configurations

## Components

### test-pub/flake.nix
Exports a `mkSystem` function that creates NixOS configurations with:
- Home Manager integration
- Configurable hostname and username
- Optional Docker support
- Basic Git setup via Home Manager

### test-priv/flake.nix
Uses the framework to define two systems:
- **desktop**: With Docker enabled
- **laptop**: Without Docker

## Testing (requires Nix with flakes enabled)

### 1. Verify the framework flake
```bash
cd /home/user/s0x1n-core/test-pub
nix flake show
```

### 2. Verify the configuration flake
```bash
cd /home/user/s0x1n-core/test-priv
nix flake show
```

Expected output:
```
git+file:///home/user/s0x1n-core/test-priv
└───nixosConfigurations
    ├───desktop: NixOS configuration
    └───laptop: NixOS configuration
```

### 3. Check the configurations
```bash
cd /home/user/s0x1n-core/test-priv
nix flake check
```

### 4. Build a configuration (dry run)
```bash
cd /home/user/s0x1n-core/test-priv
nix build .#nixosConfigurations.desktop.config.system.build.toplevel --dry-run
```

## Real-World Usage

To use this pattern in production:

1. **Host test-pub on GitHub** (or another Git hosting service)
   ```nix
   inputs.framework.url = "github:yourusername/nixos-framework";
   ```

2. **Keep test-priv private** with your specific configurations

3. **Version control** both repositories independently

4. **Update the framework** by bumping the flake lock:
   ```bash
   cd test-priv
   nix flake update framework
   ```

## Benefits

- **Separation of concerns**: Framework vs. specific configurations
- **Reusability**: Share the framework across multiple machines/repos
- **Version control**: Pin specific framework versions in test-priv
- **Privacy**: Keep machine-specific details in private repo
- **Flexibility**: Extend the framework without modifying private configs
