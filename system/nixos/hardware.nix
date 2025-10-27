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

    # lsusb
    usbutils
  ];

  # Hard disk health monitoring
  services.smartd.enable = mkDefault true;

  # # powerManagement.powertop.enable = true;
  # # services.thermald.enable = true;

  # Enable i2c for the main user to control monitors via software
  hardware.i2c.enable = true;

  systemd.watchdog = {
    runtimeTime = mkDefault "1min";
    rebootTime = mkDefault "1min";
  };

  # Bluetooth
  services.blueman.enable = mkDefault config.hardware.bluetooth.enable;

  # Enable A2DP Sink: https://nixos.wiki/wiki/Bluetooth
  hardware.bluetooth.settings = {
    General = {
      Enable = mkDefault "Source,Sink,Media,Socket";
    };
  };

  # https://get.vial.today/manual/linux-udev.html
  hardware.keyboard.qmk.enable = true;
}
