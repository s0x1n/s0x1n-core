{ lib, lanzabooteModule }:

{
  # Boot configuration builders
  lanzaboote = import ./lanzaboote.nix { inherit lib lanzabooteModule; };
  systemdBoot = import ./systemd-boot.nix { inherit lib; };
}
