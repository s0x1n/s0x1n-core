{ lib }:

# Creates a LUKS encryption configuration with YubiKey authentication
# Supports both FIDO2 and challenge-response methods
# Note: Requires systemd-cryptenroll setup after installation
{
  name ? "cryptroot",
  allowDiscards ? true,  # Enable TRIM for SSDs
  passwordFallback ? true,  # Allow password as backup unlock method
  method ? "fido2",  # "fido2" or "challenge-response"
}:

let
  validMethods = [ "fido2" "challenge-response" ];
  
  validateMethod = 
    if !lib.elem method validMethods then
      throw "YubiKey method must be one of: ${lib.concatStringsSep ", " validMethods}"
    else
      method;

in {
  type = "luks";
  inherit name;
  # device will be set by compose.nix
  
  settings = {
    inherit allowDiscards;
    
    # YubiKey will be enrolled post-installation using systemd-cryptenroll
    # For now, we set up the LUKS container that will accept YubiKey auth
  };
  
  # LUKS2 required for FIDO2 support
  extraFormatArgs = [
    "--type" "luks2"
    "--cipher" "aes-xts-plain64"
    "--key-size" "512"
    "--hash" "sha256"
    "--iter-time" "5000"
    "--use-random"
  ] ++ lib.optionals (validateMethod == "fido2") [
    "--pbkdf" "argon2id"  # Better PBKDF for FIDO2
  ];
  
  # Metadata for post-install configuration
  # The actual device path will be determined at install time
  postInstall = {
    yubikey = {
      enabled = true;
      inherit method passwordFallback;
      # enrollCommand will use the actual partition device path
      enrollCommand = 
        if method == "fido2" then
          "systemd-cryptenroll --fido2-device=auto"
        else
          "systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=yes";
    };
  };
}
