{ config, lib, pkgs, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.hardware;
in
{
  options.sys.hardware = {
    isX64 = mkEnableOption "options for x86_64 systems" // { default = pkgs.stdenv.isx86_64; };
  };

  config = {
    hardware = {
      cpu.intel.updateMicrocode = cfg.isX64;
      cpu.amd.updateMicrocode = cfg.isX64;
      enableAllFirmware = true;
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = cfg.isX64;
      };
    };

    # Firmware update service
    services.fwupd.enable = true;
    environment.systemPackages = with pkgs; [
      # Sensors (fans, temp)
      lm_sensors

      # Manually set CPU governor
      # cpupower frequency-set -g powersave
      config.boot.kernelPackages.cpupower

      # iostat
      sysstat
    ];

    services.smartd.enable = true;

    # # powerManagement.cpuFreqGovernor = "powersave";
    # # powerManagement.powertop.enable = true;
    # # services.thermald.enable = true;
  };
}
