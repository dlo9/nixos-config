{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11-small";
    #nixpkgs.url = "nixpkgs/3c0f57e36ed0cf9947281e3b31f1bebb7ce5d4a1";

    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: 
  let
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          system = prev.system;
          config.allowUnfree = true;
        };
      };
  in {
    nixosConfigurations.pavil = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Overlays-module makes "pkgs.unstable" available in configuration.nix
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })

        ./configuration.nix
        ./lib/printing.nix
        inputs.sops-nix.nixosModules.sops
      ];
    };
  };
}

