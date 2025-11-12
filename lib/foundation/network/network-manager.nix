{ lib }:

# NetworkManager configuration with declarative network connections
# Supports both imperative (nmtui) and declarative (via config files) approaches
{
  enable ? true,
  networks ? {},  # Declarative network configurations
  wifi.backend ? "wpa_supplicant",  # or "iwd"
}:

let
  # Helper to create a network connection file
  mkNetworkConnection = name: config: {
    name = "system-connections/${name}.nmconnection";
    value = {
      text = lib.generators.toINI {} {
        connection = {
          id = name;
          type = config.type or "wifi";
          autoconnect = config.autoconnect or true;
        } // (if config ? uuid then { uuid = config.uuid; } else {});
        
        # WiFi-specific settings
      } // lib.optionalAttrs (config.type or "wifi" == "wifi") {
        wifi = {
          ssid = config.ssid;
          mode = config.mode or "infrastructure";
        } // lib.optionalAttrs (config ? hidden) {
          hidden = config.hidden;
        };
        
        wifi-security = lib.optionalAttrs (config ? security) ({
          key-mgmt = config.security.keyMgmt or "wpa-psk";
        } // lib.optionalAttrs (config.security ? psk) {
          psk = config.security.psk;
        } // lib.optionalAttrs (config.security ? pskFile) {
          # For sops-encrypted passwords
          # Note: NetworkManager needs plaintext, so we'll handle this differently
        });
        
        # IPv4 settings  
        ipv4 = {
          method = config.ipv4.method or "auto";
        } // lib.optionalAttrs (config.ipv4.method or "auto" == "manual") {
          addresses = config.ipv4.addresses;
          gateway = config.ipv4.gateway;
          dns = lib.concatStringsSep ";" config.ipv4.dns;
        };
        
        # IPv6 settings
        ipv6 = {
          method = config.ipv6.method or "auto";
        };
      } // lib.optionalAttrs (config.type or "wifi" == "ethernet") {
        # Ethernet-specific settings
        ethernet = {
          auto-negotiate = config.ethernet.autoNegotiate or true;
        };
      };
      
      # File permissions (NetworkManager requires 600)
      mode = "0600";
    };
  };
  
  # Generate environment files for networks
  networkFiles = lib.mapAttrs' mkNetworkConnection networks;

in {
  # Enable NetworkManager
  networking.networkmanager = {
    enable = enable;
    wifi.backend = wifi.backend;
    
    # Enable connection files in /etc
    ensureProfiles = {
      environmentFiles = networkFiles;
    };
  };
  
  # Persist NetworkManager state if using impermanence
  # This preserves dynamically added networks (via nmtui)
  environment.persistence."/persist".directories = lib.optionals enable [
    "/etc/NetworkManager/system-connections"
  ];
  
  # Required packages for NetworkManager
  environment.systemPackages = lib.optionals enable (with lib; [
    # nmtui is included in networkmanager package
    # Add any additional network tools here
  ]);
  
  # Metadata
  meta = {
    networkManagerEnabled = enable;
    declarativeNetworks = builtins.attrNames networks;
    wifiBackend = wifi.backend;
    postInstallInstructions = ''
      NetworkManager Setup:
      
      Declarative networks configured: ${lib.concatStringsSep ", " (builtins.attrNames networks)}
      
      For ad-hoc network connections:
      1. Use nmtui (text UI):
         nmtui
      
      2. Or use nmcli (command line):
         nmcli device wifi list
         nmcli device wifi connect "SSID" password "PASSWORD"
      
      For declarative networks with sops-encrypted passwords:
      1. Add WiFi password to secrets.yaml:
         sops secrets.yaml
         # Add: wifi-home-psk: "your-wifi-password"
      
      2. Reference in network config:
         networks.home = {
           ssid = "MyHomeNetwork";
           security = {
             keyMgmt = "wpa-psk";
             pskFile = config.sops.secrets.wifi-home-psk.path;
           };
         };
      
      Note: NetworkManager state (dynamic connections) persists in /etc/NetworkManager/system-connections
    '';
  };
}
