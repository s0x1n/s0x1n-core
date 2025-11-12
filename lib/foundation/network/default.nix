{ lib }:

{
  # NetworkManager with declarative network configurations
  networkManager = import ./network-manager.nix { inherit lib; };
  
  # systemd-networkd (alternative, fully declarative)
  systemdNetworkd = import ./systemd-networkd.nix { inherit lib; };
}
