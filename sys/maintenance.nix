{ config, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.maintenance;
in
{
  options.sys.maintenance = {
    enable = mkEnableOption "system maintenance" // { default = true; };
    autoUpgrade = mkEnableOption "automatic system upgrades" // { default = false; };
  };

  config = mkIf cfg.enable {
    # Autoupgrade
    # Can be run manually with: `systemctl start nixos-upgrade.service`
    system.autoUpgrade = {
      enable = cfg.autoUpgrade;
      allowReboot = mkDefault false;
      flake = "path:///etc/nixos#${config.networking.hostName}";
      flags = [ "--recreate-lock-file" "--commit-lock-file" ];
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

    # Periodic SSD TRIM of mounted partitions
    services.fstrim.enable = true;
  };
}
