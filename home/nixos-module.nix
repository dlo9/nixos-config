{ config, inputs, lib, ... }:

with lib;

{
  imports = [
    # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "home-manager-backup";
      users.david = import ./.;
      users.root.home.stateVersion = "22.11";

      sharedModules = [
    inputs.nur.nixosModules.nur
    {
        # Add nix environment variables to home manager. This is necessary for NIX_LD
        # to work on non-interactive login (e.g., running vscode remotely)
        home.sessionVariables = (mapAttrs (n: v: (mkOptionDefault v)) config.environment.variables);
      }];

      # Pass extra arguments to home.nix
      extraSpecialArgs = {
        inherit inputs;
      };
    };
  };
}
