{ lib, niriModule }:

{
  # Niri compositor (scrollable tiling)
  niri = import ./niri.nix {
    inherit lib niriModule;
  };
}
