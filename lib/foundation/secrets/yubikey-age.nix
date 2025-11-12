{ lib }:

# Helper for using YubiKey with age/sops-nix
# YubiKeys can be used with age via yubikey-agent or age-plugin-yubikey
{
  enable ? true,
  plugin ? "yubikey-agent",  # "yubikey-agent" or "age-plugin-yubikey"
}:

let
  validPlugins = [ "yubikey-agent" "age-plugin-yubikey" ];
  
  validatePlugin =
    if !lib.elem plugin validPlugins then
      throw "YubiKey plugin must be one of: ${lib.concatStringsSep ", " validPlugins}"
    else
      plugin;

in {
  # Note: The actual package installation should be done in the system config
  # This just provides the configuration structure
  
  # Services configuration for yubikey-agent
  services = lib.mkIf (enable && plugin == "yubikey-agent") {
    yubikey-agent.enable = true;
  };
  
  # For age-plugin-yubikey, users need to install it manually or via system packages
  # environment.systemPackages = [ pkgs.age-plugin-yubikey ];
  
  # Metadata for documentation
  meta = {
    yubiKeyEnabled = enable;
    chosenPlugin = validatePlugin;
    requiredPackage = 
      if plugin == "yubikey-agent" then
        "yubikey-agent"
      else
        "age-plugin-yubikey";
    postInstallInstructions = 
      if plugin == "yubikey-agent" then ''
        YubiKey Age Setup (yubikey-agent):
        
        1. Install yubikey-agent and setup:
           yubikey-agent -setup
        
        2. Get your age public key:
           yubikey-agent -list
        
        3. Use this public key in your .sops.yaml:
           keys:
             - &yubikey age1yubikey1...
           creation_rules:
             - path_regex: secrets\.yaml$
               key_groups:
                 - age:
                     - *yubikey
        
        4. The YubiKey will be used automatically for decryption
           when the agent is running
      ''
      else ''
        YubiKey Age Setup (age-plugin-yubikey):
        
        1. Install age-plugin-yubikey:
           nix-shell -p age-plugin-yubikey
        
        2. List available YubiKey PIV slots:
           age-plugin-yubikey --list
        
        3. Generate a key on your YubiKey (if needed):
           age-plugin-yubikey --generate --slot 82
        
        4. Get your age identity:
           age-plugin-yubikey --identity --slot 82
        
        5. Get your age recipient (public key):
           age-plugin-yubikey --list
        
        6. Use the recipient in your .sops.yaml:
           keys:
             - &yubikey age1yubikey1...
           creation_rules:
             - path_regex: secrets\.yaml$
               key_groups:
                 - age:
                     - *yubikey
        
        7. Configure sops to use the YubiKey identity:
           export SOPS_AGE_KEY=$(age-plugin-yubikey --identity --slot 82)
      '';
  };
}

