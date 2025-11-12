{ lib }:

# Creates a LUKS encryption configuration with password authentication
# Returns a function that creates encryption config (device will be provided by compose)
{
  name ? "cryptroot",
  allowDiscards ? true,  # Enable TRIM for SSDs
  passwordFile ? null,    # Optional: path to password file for automated unlock
}:

{
  type = "luks";
  inherit name;
  # device will be set by compose.nix
  
  settings = {
    inherit allowDiscards;
  } // lib.optionalAttrs (passwordFile != null) {
    keyFile = passwordFile;
  };
  
  # Additional LUKS settings for security
  extraFormatArgs = [
    "--type" "luks2"
    "--cipher" "aes-xts-plain64"
    "--key-size" "512"
    "--hash" "sha256"
    "--iter-time" "5000"
    "--use-random"
  ];
}
