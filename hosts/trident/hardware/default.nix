{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
with lib; {
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc-ssd
    raspberry-pi-4

    #./disks.nix
    ./generated.nix
  ];

  boot.kernelParams = [
    # Rotate the kernel console 180 degrees
    "fbcon=rotate:2"
  ];

  # Force remote builders
  nix.settings.max-jobs = 0;

  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      touch-ft5406.enable = true;
    };

    # Examine device tree:
    #   - nix shell nixpkgs#dtc -c fdtdump /boot/firmware/bcm2711-rpi-4-b.dtb
    #   - nix run nixpkgs#dtc -- --sort /proc/device-tree | less
    #   - Live load/unload: nix shell nixpkgs#libraspberrypi -c sudo dtoverlay -d "$(dirname "$(realpath /run/current-system/kernel)")/dtbs/overlays/" vc4-kms-dsi-generic
    # References:
    #   - https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/configuration/device-tree.adoc
    #   - https://github.com/raspberrypi/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/vc4-kms-dpi.dtsi
    #   - https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/4/modesetting.nix
    deviceTree = {
      enable = true;

      overlays = [
        {
          # This rotates the display and is a modification of:
          # https://github.com/NixOS/nixos-hardware/blob/8870dcaff63dfc6647fb10648b827e9d40b0a337/raspberry-pi/4/touch-ft5406.nix#L48-L49
          # Might also be able to rotate this way:
          # https://www.raspberrypi.com/documentation/accessories/touch-display-2.html#rotate-screen-without-a-desktop
          name = "rpi-ft5406-overlay-rotate";
          dtsText = ''
            /dts-v1/;
            /plugin/;

            / {
            	compatible = "brcm,bcm2711";

            	fragment@0 {
            		target-path = "/soc/firmware";
            		__overlay__ {
            			ts: touchscreen {
            				compatible = "raspberrypi,firmware-ts";
                    touchscreen-inverted-x;
                    touchscreen-inverted-y;
            			};
            		};
            	};
            };
          '';
        }
      ];
    };
  };

  boot.loader = {
    generic-extlinux-compatible = {
      enable = true;
      configurationLimit = 8;
    };

    systemd-boot.enable = false;
    grub.enable = false;
  };

  boot.initrd.systemd.tpm2.enable = false;

  # Some filesystems aren't needed, and keep the image small
  boot.supportedFilesystems = {
    zfs = mkForce false;
    cifs = mkForce false;
  };

  # No hard drives
  services.smartd.enable = false;
}
