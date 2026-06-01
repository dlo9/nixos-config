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

  # nixos-hardware's raspberry-pi-4 module defaults to a custom rpi kernel
  # that no public cache builds, forcing a local rebuild on every deploy.
  # Mainline supports bcm2711 and is cached by Hydra.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # vc4-drm binds the pixelvalves at boot, but mainline's DT doesn't enable
  # the DSI panel (no upstream vc4-kms-dsi-7inch overlay), so vc4 drives the
  # DSI lines with garbage and the panel falls back to test-pattern flashing.
  # Blacklisting vc4 hands the display back to the closed VC firmware, which
  # initializes the DSI panel and exposes a simple-framebuffer the kernel
  # picks up via simpledrm. v3d (GPU compute) is a separate module and stays.
  boot.blacklistedKernelModules = ["vc4"];

  # Mount the VC firmware FAT partition so we can manage config.txt declaratively.
  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = ["nofail"];
  };

  # The official 7" DSI touchscreen is physically mounted upside-down. Ask the
  # closed VC firmware to rotate both the panel scan-out and the touch
  # coordinates 180 degrees, so every layer above (fbcon, simpledrm, wlroots,
  # KlipperScreen) gets an already-correct framebuffer and untransformed
  # touches that line up with the display.
  system.activationScripts.rpi-display-rotate = ''
    cfg=/boot/firmware/config.txt
    if [[ -f $cfg ]] && ! ${pkgs.gnugrep}/bin/grep -q '^display_lcd_rotate=2$' "$cfg"; then
      printf '\n# Managed by NixOS: rotate official 7" DSI touchscreen 180 degrees\ndisplay_lcd_rotate=2\n' >> "$cfg"
    fi
  '';

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

      # display_lcd_rotate=2 rotates the panel scan-out but not the firmware
      # touch buffer, so touch comes through in raw FT5406 orientation. Invert
      # both axes here so raspberrypi-ts (via touchscreen_parse_properties)
      # reports coordinates matching the rotated display.
      overlays = [
        {
          name = "rpi-ft5406-overlay-invert";
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
