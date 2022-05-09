{ config, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.maintenance;
in
{
  options.sys.maintenance = {
    enable = mkEnableOption "system maintenance" // { default = true; };
  };

  config = mkIf cfg.enable {
    # Autoupgrade
    system.autoUpgrade = {
      enable = true;
      allowReboot = true;
      flake = "github:NixOS/nixpkgs/nixos-21.11-small";
      flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
      dates = "Sat, 02:00";
    };

    # Store maintenance
    nix = {
      extraOptions = ''
        keep-outputs = true
        keep-derivations = true
      '';

      gc = {
        automatic = true;
        dates = "Sat, 01:00";
        options = "--delete-older-than 14d";
      };

      optimise = {
        automatic = true;
        dates = [ "Sat, 03:00" ];
      };
    };
  };
}
