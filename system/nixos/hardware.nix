{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  hardware = {
    # TODO: remove and use host-based hardware instead
    cpu.intel.updateMicrocode = mkDefault pkgs.stdenv.isx86_64;
    cpu.amd.updateMicrocode = mkDefault pkgs.stdenv.isx86_64;

    enableAllFirmware = mkDefault true;

    opengl = {
      enable = mkDefault true;
      driSupport = mkDefault true;
      driSupport32Bit = pkgs.stdenv.isx86_64;
    };
  };

  # Firmware update service
  services.fwupd.enable = mkDefault true;

  environment.systemPackages = with pkgs; [
    # Sensors (fans, temp)
    lm_sensors

    # Manually set CPU governor
    # cpupower frequency-set -g powersave
    config.boot.kernelPackages.cpupower

    # iostat
    sysstat
  ];

  # Hard disk health monitoring
  services.smartd.enable = mkDefault true;

  # # powerManagement.powertop.enable = true;
  # # services.thermald.enable = true;

  # Enable i2c for the main user to control monitors via software
  hardware.i2c.enable = true;
}
