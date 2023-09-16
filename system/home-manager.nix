{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = mkDefault true;
    useUserPackages = mkDefault true;
    backupFileExtension = "home-manager-backup";

    # Add a user like this:
    # users."${user}" = {config, lib, ...}: { // my settings; };

    sharedModules = [
      inputs.nur.nixosModules.nur
      {
        # Add nix environment variables to home manager. This is necessary for NIX_LD
        # to work on non-interactive login (e.g., running vscode remotely)
        home.sessionVariables = mapAttrs (n: v: (mkOptionDefault v)) config.environment.variables;
      }
    ];

    # Pass extra arguments to home.nix
    extraSpecialArgs = {
      inherit inputs;
      isLinux = pkgs.stdenv.isLinux;
    };
  };
}
