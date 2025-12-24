{
  description = "Public NixOS configuration framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
  {
    mkSystem = { hostname, username, enableDocker ? false }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          {
            networking.hostName = hostname;

            users.users.${username} = {
              isNormalUser = true;
              extraGroups = [ "wheel" ] ++ (if enableDocker then [ "docker" ] else []);
            };

            home-manager.users.${username} = {
              home.stateVersion = "24.11";
              programs.git.enable = true;
            };

            services.docker.enable = enableDocker;
          }
        ];
      };
  };
}
