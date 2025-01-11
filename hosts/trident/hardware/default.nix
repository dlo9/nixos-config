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
    # ./quirks.nix
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

      overlays = let
        btt-display = pkgs.fetchFromGitHub {
          owner = "bigtreetech";
          repo = "TFT43-DIP";
          rev = "a4409952502d7e09521454c530ff728bd5856542";
          hash = "sha256-mlkuc5cWJ0qjYV9KgHRTF3JxzOeOe7e++4D54I7p+uY=";
        };

        tft43-display = pkgs.runCommand "tft43-display" {} ''
          mkdir $out

          ${pkgs.libraspberrypi}/bin/dtoverlay \
            -d ${config.hardware.deviceTree.dtbSource}/overlays \
            -D vc4-kms-dpi-generic \
            rgb666-padhi=true \
            clock-frequency=32000000 \
            hactive=800 \
            hfp=16 \
            hsync=1 \
            hbp=46 \
            vactive=480 \
            vfp=7 \
            vsync=3 \
            vbp=23 \
            backlight-gpio=19 \
            rotate=0

            mv dry_run.dtbo "$out/tft43-display.dtbo"
        '';
      in [
        #{
        #  name = "rpi-tft43-overlay";
        #  dtboFile = "${btt-display}/gt911_btt_tft43_dip.dtbo";
        #  dtsFile = "${btt-display}/gt911_btt_tft43_dip.dts";
        #}
        #{
        #  name = "vc4-kms-dpi-generic";
        #  dtboFile = "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/vc4-kms-dpi-generic.dtbo";

          #dtsFile = pkgs.fetchurl {
          #  url = "https://raw.githubusercontent.com/raspberrypi/linux/refs/heads/rpi-6.6.y/arch/arm/boot/dts/overlays/vc4-kms-dpi-generic-overlay.dts";
          #  hash = "sha256-+YJKM5S79Y1K+T1ihGXvGAutZkJci/gJzQTKfO4h7gw=";
          #};
        #}
        #{
        #  name = "vc4-kms-v3d";
        #  # Required by the generic display below
        #  dtboFile = "${config.hardware.deviceTree.dtbSource}/overlays/vc4-kms-v3d-pi4.dtbo";
        #}
        #{
        #  name = "vc4-kms-dsi-7inch";
        #  dtboFile = "${tft43-display}/vc4-kms-dsi-7inch.dtbo";
        #}
        #{
        #  name = "tft43-display";
        #  dtboFile = "${tft43-display}/tft43-display.dtbo";
        #}
        #{
        #  name = "generic-dpi-display";
        #  # Alternate path when using stock kernel: ${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays
        #  dtboFile = "${config.hardware.deviceTree.dtbSource}/overlays/vc4-kms-dpi-generic.dtbo";
        #}
        {
          # This rotates the display and is a modification of:
          # https://github.com/NixOS/nixos-hardware/blob/8870dcaff63dfc6647fb10648b827e9d40b0a337/raspberry-pi/4/touch-ft5406.nix#L48-L49
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
    generic-extlinux-compatible.enable = true;
    systemd-boot.enable = false;
    grub.enable = false;
  };

  boot.initrd.systemd.tpm2.enable = false;

  # Some filesystems aren't needed, and keep the image small
  boot.supportedFilesystems = {
    zfs = mkForce false;
    cifs = mkForce false;
  };

  services.smartd.enable = false;
}
