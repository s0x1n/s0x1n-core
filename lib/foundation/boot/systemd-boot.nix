{ lib }:

# Creates a standard systemd-boot configuration (no secure boot)
{
  enable ? true,
  configurationLimit ? 10,  # Number of generations to keep in boot menu
  consoleMode ? "auto",     # "auto", "max", "keep", or specific resolution
}:

{
  boot.loader.systemd-boot = {
    inherit enable configurationLimit consoleMode;
    editor = false;  # Disable boot menu editor for security
  };
  
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Optional: timeout for boot menu
  boot.loader.timeout = 5;
}
