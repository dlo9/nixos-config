{
  config,
  pkgs,
  lib,
  ...
}:
# Declarative klipper MCU firmware + flash scripts.
#
# Each MCU listed below produces two packages in the system environment:
#   klipper-firmware-<name>  — the built artifacts (klipper.bin / .uf2 / .config)
#   klipper-flash-<name>     — a wrapper that flashes that MCU
#
# The firmware is built from `pkgs.klipper.src`, so it's always in lockstep
# with the host klippy version — eliminating the "MCU has deprecated code"
# warnings whenever nixpkgs bumps klipper.
#
# To (re)generate a firmware config interactively:
#   mkdir -p hosts/trident/firmware && cd hosts/trident/firmware
#   nix run nixpkgs#klipper-genconf
#   mv config <mcu-name>.cfg
#
# MCUs whose .cfg file is missing are silently skipped, so this module is
# safe to import before any configs have been captured.
let
  mcus = {
    # Config settings: https://ldomotion.com/p/guide/VORON-Leviathan-V12#section-3
    mcu = {
      firmwareConfig = ../firmware/mcu.cfg;
      flashDevice = "/dev/serial/by-id/usb-Klipper_stm32f446xx_3F0019000751303532383235-if00";
    };

    # Config settings: https://docs.ldomotors.com/en/Toolboard/nitehawk-sb#compiling-klipper-firmware
    nhk = {
      firmwareConfig = ../firmware/nhk.cfg;
      flashDevice = "/dev/serial/by-id/usb-Klipper_rp2040_4E363334320B17B3-if00";
    };
  };

  presentMcus = lib.filterAttrs (_: v: builtins.pathExists v.firmwareConfig) mcus;

  # Pulls a `CONFIG_FOO=...` value from the firmware .config text.
  # Returns null if absent. Strips surrounding quotes from string values.
  readConfigField = text: field: let
    matchLine = line: let
      stripped = lib.removePrefix "${field}=" line;
    in
      if stripped != line
      then lib.removePrefix "\"" (lib.removeSuffix "\"" stripped)
      else null;
    matches = lib.filter (x: x != null) (map matchLine (lib.splitString "\n" text));
  in
    if matches == []
    then null
    else builtins.head matches;

  mkPackages = name: {
    firmwareConfig,
    flashDevice,
  }: let
    firmware = pkgs.klipper-firmware.override {
      mcu = name;
      inherit firmwareConfig;
    };

    cfg = builtins.readFile firmwareConfig;
    mcuType = readConfigField cfg "CONFIG_MCU";
    startAddr = readConfigField cfg "CONFIG_FLASH_APPLICATION_ADDRESS";

    # `flash_usb.py` resolves helper scripts/binaries via relative paths
    # (`lib/canboot/flash_can.py`, `lib/rp2040_flash/rp2040_flash`, …). Some
    # live in the klipper source tree, others are compiled per-MCU. Build a
    # workdir that overlays the firmware's lib/ on top of the source's lib/.
    flashWorkdir = pkgs.runCommand "klipper-flash-${name}-workdir" {} ''
      mkdir -p $out/lib
      for d in ${pkgs.klipper.src}/lib/*; do
        ln -s "$d" "$out/lib/$(basename "$d")"
      done
      if [ -d ${firmware}/lib ]; then
        for d in ${firmware}/lib/*; do
          rm -f "$out/lib/$(basename "$d")"
          ln -s "$d" "$out/lib/$(basename "$d")"
        done
      fi
    '';

    # nixpkgs' upstream klipper-flash forgets to pass -s (required by
    # flash_usb.py on STM32) and runs from the firmware output dir, which
    # is missing the vendored scripts. Hand-roll the invocation instead.
    #
    # Also: when a previous flash failed, the board can be stuck in Katapult
    # bootloader, showing up as `usb-katapult_…` instead of `usb-Klipper_…`.
    # Pick whichever path actually exists.
    flasher = pkgs.writeShellApplication {
      name = "klipper-flash-${name}";
      runtimeInputs = with pkgs; [python3 stm32flash dfu-util];
      text = ''
        device=${flashDevice}
        if [ ! -e "$device" ]; then
          case "$device" in
            *usb-Klipper_*)  alt="''${device//usb-Klipper_/usb-katapult_}" ;;
            *usb-katapult_*) alt="''${device//usb-katapult_/usb-Klipper_}" ;;
            *)               alt="" ;;
          esac
          if [ -n "$alt" ] && [ -e "$alt" ]; then
            echo "Configured device $device not present; using $alt instead" >&2
            device="$alt"
          fi
        fi
        cd ${flashWorkdir}
        exec ${pkgs.klipper}/lib/scripts/flash_usb.py \
          -t ${mcuType} \
          -d "$device" \
          -s ${startAddr} \
          ${firmware}/klipper.bin "$@"
      '';
    };
  in [firmware flasher];

  # Stops klipper, flashes every present MCU, then restarts klipper.
  # Needs sudo for the systemctl calls.
  flashAll = pkgs.writeShellApplication {
    name = "klipper-flash-all";
    text = ''
      systemctl stop klipper
      trap 'systemctl start klipper' EXIT
      ${lib.concatMapStringsSep "\n" (name: "klipper-flash-${name}") (lib.attrNames presentMcus)}
    '';
  };
in {
  environment.systemPackages =
    lib.flatten (lib.mapAttrsToList mkPackages presentMcus)
    ++ lib.optional (presentMcus != {}) flashAll;
}
