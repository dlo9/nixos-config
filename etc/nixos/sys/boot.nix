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
        #"nomodeset" # TODO: server only
        "boot_on_fail"
      ];

      loader = {
        timeout = 1;
        grub = {
          enable = true;
          configurationLimit = 20;
          splashImage = null; # I want all the text
          zfsSupport = true;
          useOSProber = true;
          efiSupport = true;
          #mirroredBoots = [];  # TODO
        };

        # TODO: swap when using installer
        efi.canTouchEfiVariables = true;
        # boot.loader.grub.efiInstallAsRemovable = true;
      };
    };
  };
}
