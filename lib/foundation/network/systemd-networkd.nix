{ lib }:

# systemd-networkd configuration (fully declarative alternative to NetworkManager)
# NOTE: This is incompatible with NetworkManager - choose one or the other
{
  enable ? true,
  networks ? {},  # Network configurations
  useNetworkd ? true,
  useDHCP ? false,  # Global DHCP setting
}:

let
  # Helper to create a .network file configuration
  mkNetwork = name: config: {
    name = "${name}";
    value = {
      matchConfig = config.matchConfig or {};
      
      networkConfig = {
        DHCP = config.dhcp or "yes";
      } // (config.networkConfig or {});
      
      # Static addressing
    } // lib.optionalAttrs (config ? address) {
      address = config.address;
    } // lib.optionalAttrs (config ? gateway) {
      gateway = config.gateway;
    } // lib.optionalAttrs (config ? dns) {
      dns = config.dns;
    };
  };
  
  # Generate network configurations
  systemdNetworks = lib.mapAttrs' mkNetwork networks;

in {
  networking = {
    # Enable systemd-networkd
    useNetworkd = useNetworkd;
    useDHCP = useDHCP;
    
    # Disable NetworkManager (incompatible with networkd)
    networkmanager.enable = lib.mkForce false;
  };
  
  # systemd-networkd configuration
  systemd.network = {
    enable = enable;
    networks = systemdNetworks;
  };
  
  # For WiFi with networkd, you need wpa_supplicant separately
  networking.wireless = lib.mkIf enable {
    enable = true;  # Enable if you need WiFi
    # Configure networks via networking.wireless.networks
  };
  
  # Metadata
  meta = {
    systemdNetworkdEnabled = enable;
    configuredNetworks = builtins.attrNames networks;
    postInstallInstructions = ''
      systemd-networkd Setup:
      
      Configured networks: ${lib.concatStringsSep ", " (builtins.attrNames networks)}
      
      NOTE: systemd-networkd is fully declarative and does NOT support
      ad-hoc network connections like NetworkManager's nmtui.
      
      For WiFi, you need to configure wpa_supplicant separately:
      networking.wireless.networks = {
        "MyNetwork" = {
          psk = "password";  # Use sops for this!
        };
      };
      
      To see network status:
        networkctl status
        networkctl list
      
      For WPA supplicant status:
        wpa_cli status
    '';
  };
}
