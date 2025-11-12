{
  description = "Modular NixOS foundation framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, impermanence, home-manager, lanzaboote, sops-nix, niri }: {
    lib = import ./lib { 
      inherit (nixpkgs) lib;
      diskoLib = disko.lib;
      impermanenceModule = impermanence.nixosModules.impermanence;
      homeManagerModule = home-manager.nixosModules.home-manager;
      lanzabooteModule = lanzaboote.nixosModules.lanzaboote;
      sopsModule = sops-nix.nixosModules.sops;
      niriModule = niri.homeModules.niri;
    };
  };
}
