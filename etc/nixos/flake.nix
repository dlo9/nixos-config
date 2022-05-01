{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Something broke sleep between this commit and nixos-21.11-small
    # https://github.com/NixOS/nixpkgs/commit/ccb90fb9e11
    nixpkgs.url = "github:NixOS/nixpkgs/ccb90fb9e11";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11-small";

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

