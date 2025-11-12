{ lib, lanzabooteModule }:

# Creates a lanzaboote (secure boot) configuration
# Lanzaboote wraps systemd-boot and signs boot files for UEFI Secure Boot
{
  enable ? true,
  pkiBundle ? "/etc/secureboot",  # Path where secure boot keys are stored
}:

{
  imports = [ lanzabooteModule ];
  
  # Lanzaboote replaces systemd-boot for secure boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  
  boot.lanzaboote = {
    enable = enable;
    inherit pkiBundle;
  };
  
  # Required for secure boot
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Metadata for post-install setup
  meta = {
    secureBootEnabled = enable;
    postInstallInstructions = ''
      Secure Boot Setup Required:
      
      1. Generate secure boot keys:
         sudo sbctl create-keys
      
      2. Enroll keys (after rebooting to UEFI setup and enabling Setup Mode):
         sudo sbctl enroll-keys --microsoft
      
      3. Verify secure boot status:
         sudo sbctl status
      
      4. Sign your boot files:
         sudo sbctl verify
         sudo sbctl sign-all
      
      5. Reboot and enable Secure Boot in UEFI settings
      
      Keys are stored in: ${pkiBundle}
    '';
  };
}
