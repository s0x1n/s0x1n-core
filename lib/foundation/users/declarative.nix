{ lib }:

# Creates declarative user configurations
# Supports hashed passwords (from sops or directly specified)
{
  users ? {},  # Attrset of user configurations
  mutableUsers ? false,  # Whether to allow imperative user management
}:

let
  # Helper to create a single user configuration
  mkUser = username: config: {
    isNormalUser = config.isNormalUser or true;
    isSystemUser = config.isSystemUser or false;
    
    # User description
    description = config.description or username;
    
    # Groups
    extraGroups = config.extraGroups or [];
    
    # Home directory (defaults to /home/username for normal users)
    home = config.home or (if config.isNormalUser or true then "/home/${username}" else null);
    
    # Shell
    shell = config.shell or null;  # null uses default shell
    
    # UID (optional, for consistent UIDs across systems)
    uid = config.uid or null;
    
    # Password configuration
    # Priority: hashedPasswordFile > hashedPassword > initialPassword (avoid!)
  } // (
    if config ? hashedPasswordFile then
      # Use hashed password from file (e.g., sops secret)
      { inherit (config) hashedPasswordFile; }
    else if config ? hashedPassword then
      # Use directly specified hashed password
      { inherit (config) hashedPassword; }
    else if config ? initialPassword then
      # Initial password (plaintext, not recommended!)
      { inherit (config) initialPassword; }
    else
      # No password set - user must set one manually or use key-based auth
      {}
  ) // (
    # SSH authorized keys
    if config ? openssh then
      {
        openssh.authorizedKeys = {
          keys = config.openssh.authorizedKeys or [];
          keyFiles = config.openssh.authorizedKeyFiles or [];
        };
      }
    else {}
  );
  
  # Convert user config attrset to NixOS users.users format
  usersConfig = lib.mapAttrs mkUser users;

in {
  users = {
    # Disable mutable users (all users managed declaratively)
    inherit mutableUsers;
    
    # User configurations
    users = usersConfig;
  };
  
  # If using impermanence, ensure home directories are created in persist
  # This is handled by the impermanence module, but we add tmpfiles rules as backup
  systemd.tmpfiles.rules = 
    lib.mapAttrsToList (username: config:
      let
        home = config.home or "/home/${username}";
        uid = if config ? uid then toString config.uid else "-";
      in
        "d ${home} 0700 ${username} users -"
    ) (lib.filterAttrs (n: v: v.isNormalUser or true) users);
  
  # Metadata
  meta = {
    configuredUsers = builtins.attrNames users;
    mutableUsers = mutableUsers;
    postInstallInstructions = ''
      User Management:
      
      Users are managed declaratively. To add/modify users, update your configuration.
      
      For password management with sops:
      1. Generate hashed password:
         mkpasswd -m sha-512
      
      2. Add to secrets.yaml:
         sops secrets.yaml
         # Add: user-password: "$6$..."
      
      3. Reference in user config:
         hashedPasswordFile = config.sops.secrets.user-password.path;
      
      Configured users: ${lib.concatStringsSep ", " (builtins.attrNames users)}
    '';
  };
}
