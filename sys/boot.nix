{ config, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.boot;
in
{
  options.sys.boot = { };

  config = {
    boot = {
      kernelParams = [
        "boot_on_fail"
      ];

      loader = {
        timeout = 1;
        grub = {
          enable = mkDefault true;
          configurationLimit = 10;
          splashImage = null; # I want all the text
          zfsSupport = true;
          useOSProber = true;
          efiSupport = true;
          efiInstallAsRemovable = mkDefault false;
        };

        # TODO: swap when using installer
        efi.canTouchEfiVariables = mkDefault true;
        # boot.loader.grub.efiInstallAsRemovable = true;
      };
    };
  };
}
