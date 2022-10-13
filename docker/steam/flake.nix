{
  inputs = {
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixos-unstable;
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05-small;

    flake-utils.url = "github:numtide/flake-utils";
  };

  # nix build 'path:.'
  #outputs = { self, ... }@inputs:
  #(inputs.flake-utils.lib.eachDefaultSystem
  #    (system:
  #      let
  #        pkgs = inputs.nixpkgs.legacyPackages.${system};
  #      in
  #      {
  #        packages."${system}" = rec {
  #          default = steam;
  #          steam = (import ../steam.nix { inherit pkgs; });
  #        };
  #      }
  #  ));

  outputs = inputs: {
    packages.x86_64-linux.default = (import ./steam.nix {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux;
    });
  };
}
