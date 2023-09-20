{
  config,
  inputs,
  lib,
  pkgs,
  isLinux,
  isDarwin,
  ...
}:
with lib; {
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
      inherit inputs isLinux isDarwin;
    };
  };
}
