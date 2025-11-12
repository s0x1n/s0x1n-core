{ lib }:

{
  # Declarative user management
  declarative = import ./declarative.nix { inherit lib; };
}
