{
  description = "NixOS + Home Manager config for stefanOS Howling Hyrax";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, flake-utils, ... }@inputs:

    # Apply to all default systems (x86_64-linux, aarch64-linux, etc.)
    flake-utils.lib.eachDefaultSystem (system: {
      # Optional: expose a default package per system
      packages.default = (import nixpkgs { inherit system; config.allowUnfree = true; }).hello;
    }) // {

      #---NixOS System Configuration---#
      nixosConfigurations.enterprise = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = { inherit inputs; };  # Pass inputs to modules if needed

        modules = [
          ./hardware-configuration.nix
          ./hosts/enterprise.nix

          #--Home Manager--#
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.users.bread = import ./users/bread.nix;

            #---Overlay---#
            /* Make unstable packages available as `unstable.<pkg>` */
            nixpkgs.overlays = [
              (final: prev: {
                unstable = import nixpkgs-unstable {
                  system = final.system;
                  config.allowUnfree = true;
                };
              })
            ];
          }
        ];
      };
    };
}
