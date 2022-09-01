{ config, pkgs, lib, ... }:

{
  config = {
    mobile = {
      adbd.enable = true;

      boot.stage-1 = {
        fbterm.enable = true;

        networking = {
          enable = true;

          # These are the defaults, but are here for easy reference
          IP = "172.16.42.1";
          hostIP = "172.16.42.2";
        };

        kernel = {
          allowMissingModules = false;

          # https://github.com/NixOS/mobile-nixos/pull/506
          #useNixOSKernel = true;
        };

        shell.shellOnFail = true;
        #ssh.enable = true;
      };
    };

    hardware.firmware = [
      (config.mobile.device.firmware.override {
        modem = ./firmware;
      })
    ];

    sys = {
      kernel = false;
      low-power = true;
      gaming.enable = false;
      graphical.enable = false;
      zfs.enable = false;
    };

    # This kernel does not support rpfilter
    networking.firewall.checkReversePath = false;
  };
}
