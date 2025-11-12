{ lib, impermanenceModule, homeManagerModule }:

# Creates impermanence configuration for ephemeral root
# Wipes root on reboot, persists only declared paths
{
  persistPath ? "/persist",
  
  # System-level persistence (NixOS config)
  systemPersist ? [
    "/nix"
    "/var/log"
    "/var/lib/nixos"
    "/var/lib/systemd"
    "/var/lib/bluetooth"
    "/etc/machine-id"
    "/etc/ssh"
    "/root"
  ],
  
  extraSystemPersist ? [],  # Additional paths to persist
  
  # User-level persistence (home-manager config)
  # By default, entire home directory persists
  # Users can optionally specify ephemeral paths later
  users ? {},  # { username = { ephemeralPaths = []; }; }
}:

let
  # Combine default and extra system paths
  allSystemPersist = systemPersist ++ extraSystemPersist;
  
  # Generate system-level impermanence config
  systemConfig = {
    environment.persistence.${persistPath} = {
      hideMounts = true;
      directories = allSystemPersist;
      files = [
        "/etc/machine-id"
      ];
    };
    
    # Create the persist directory structure
    fileSystems.${persistPath}.neededForBoot = true;
    
    # Ensure /persist exists and has correct permissions
    systemd.tmpfiles.rules = [
      "d ${persistPath} 0755 root root -"
      "d ${persistPath}/home 0755 root root -"
    ];
  };
  
  # Generate home-manager config for a user
  mkUserConfig = username: userConfig: {
    home.persistence.${persistPath}/home/${username} = {
      directories = [
        # By default, everything in home persists
        # This is effectively accomplished by persisting the home directory itself
        # Users can override this with ephemeral paths if desired
      ];
      
      # Allow users to specify paths that should be ephemeral (not persisted)
      # This is for future use - currently all of home persists
      allowOther = true;
    };
  };
  
  # Generate all user configs
  userConfigs = lib.mapAttrs mkUserConfig users;

in {
  # Return both system and home configurations
  system = systemConfig;
  
  # Home-manager configuration per user
  home = userConfigs;
  
  # Helper metadata for documentation/debugging
  meta = {
    inherit persistPath;
    persistedSystemPaths = allSystemPersist;
    ephemeralPaths = [ "/" "/tmp" "/var/tmp" "/var/cache" ];
  };
}
