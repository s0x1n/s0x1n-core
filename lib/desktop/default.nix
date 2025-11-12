{ lib, niriModule }:

{
  # Wayland compositors
  wayland = import ./wayland {
    inherit lib niriModule;
  };
}
