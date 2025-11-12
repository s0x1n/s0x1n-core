{ lib, sopsModule }:

# Creates a sops-nix configuration for managing secrets
# Supports age encryption with YubiKey or regular age keys
{
  defaultSopsFile ? null,  # Path to default secrets file (e.g., ./secrets.yaml)
  ageKeyFile ? "/persist/var/lib/sops-nix/key.txt",  # Where age key is stored
  secrets ? {},  # Attrset of secrets to configure
}:

let
  # Helper to create a secret configuration
  mkSecret = name: config: {
    inherit name;
    value = {
      sopsFile = config.file or defaultSopsFile;
      # Additional per-secret options
    } // (if config ? owner then { inherit (config) owner; } else {})
      // (if config ? group then { inherit (config) group; } else {})
      // (if config ? mode then { inherit (config) mode; } else {})
      // (if config ? path then { inherit (config) path; } else {});
  };
  
  secretsConfig = lib.mapAttrs' mkSecret secrets;

in {
  imports = [ sopsModule ];
  
  sops = {
    # Default sops file for all secrets (can be overridden per-secret)
    defaultSopsFile = if defaultSopsFile != null then defaultSopsFile else
      throw "sops: defaultSopsFile must be specified";
    
    # Age key configuration
    age = {
      # Path to age key file
      keyFile = ageKeyFile;
      
      # Generate a key if it doesn't exist
      generateKey = true;
      
      # Alternatively, for YubiKey-based age keys, this will be set up differently
      # (see yubikey-age.nix)
    };
    
    # Configure secrets
    secrets = secretsConfig;
  };
  
  # Ensure sops directories exist and have correct permissions
  systemd.tmpfiles.rules = [
    "d /persist/var/lib/sops-nix 0700 root root -"
  ];
  
  # Metadata for documentation
  meta = {
    secretsConfigured = builtins.attrNames secrets;
    defaultSecretsFile = defaultSopsFile;
    postInstallInstructions = ''
      sops-nix Setup:
      
      1. Install sops and age:
         nix-shell -p sops age
      
      2. Generate or import age key:
         # Generate new key
         age-keygen -o ${ageKeyFile}
         
         # Or for YubiKey, see yubikey-age.nix
      
      3. Get the public key:
         age-keygen -y ${ageKeyFile}
      
      4. Create secrets file (${if defaultSopsFile != null then defaultSopsFile else "secrets.yaml"}):
         sops secrets.yaml
      
      5. Configure .sops.yaml with your age public key:
         keys:
           - &admin <your-age-public-key>
         creation_rules:
           - path_regex: secrets\.yaml$
             key_groups:
               - age:
                   - *admin
      
      6. Edit secrets:
         sops secrets.yaml
    '';
  };
}
