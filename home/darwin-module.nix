{ config, inputs, lib, ... }:

with lib;

{
  imports = [
    # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
    inputs.home-manager.darwinModules.home-manager
  ];

  config = {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "home-manager-backup";
                users.dorchard = ({lib, ...}: {
                  imports = [ ./. ];
                  config = {

                    # TODO: check host platform instead
                  wayland.windowManager.sway.enable = lib.mkForce false;
                  services.swayidle.enable = lib.mkForce false;
                  services.mako.enable = lib.mkForce false;
                  programs.waybar.enable = lib.mkForce false;
                  programs.swaylock.enable = lib.mkForce false;
                  xdg.mimeApps.enable = lib.mkForce false;
                  home.pointerCursor = lib.mkForce null;
                };
                });

      sharedModules = [

    inputs.nur.nixosModules.nur
        {
        # Add nix environment variables to home manager. This is necessary for NIX_LD
        # to work on non-interactive login (e.g., running vscode remotely)
        home.sessionVariables = (mapAttrs (n: v: (mkOptionDefault v)) config.environment.variables);
      }


      ];

                # Pass extra arguments to home.nix
                extraSpecialArgs = {
                  inherit inputs;
                };
              };
    };
}
