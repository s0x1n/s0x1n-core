{ lib, diskoLib, impermanenceModule, homeManagerModule, lanzabooteModule, sopsModule, niriModule }:

{
  # Foundation layer - immutable/hard-to-change components
  foundation = {
    storage = import ./foundation/storage {
      inherit lib diskoLib impermanenceModule homeManagerModule;
    };
    
    boot = import ./foundation/boot {
      inherit lib lanzabooteModule;
    };
    
    secrets = import ./foundation/secrets {
      inherit lib sopsModule;
    };
    
    users = import ./foundation/users {
      inherit lib;
    };
    
    network = import ./foundation/network {
      inherit lib;
    };
  };
  
  # Desktop layer - user environment and compositor configurations
  desktop = import ./desktop {
    inherit lib niriModule;
  };
}
