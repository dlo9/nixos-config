{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  user =
    if isLinux
    then "david"
    else "dorchard";
in {
  imports = [
    # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "home-manager-backup";
    users."${user}" = import ./.;

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
      inherit inputs isLinux;
    };
  };
}
