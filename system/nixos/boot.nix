{
  lib,
  config,
  ...
}:
with lib; {
  boot = {
    initrd = {
      # Enable systemd in init
      systemd.enable = mkDefault true;

      kernelModules = [
        # Allow complex networking configurations during boot
        "macvlan"
        "bridge"
      ];
    };

    kernelParams = [
      "boot_on_fail"

      # Enable emergency access, even with root account locked
      # TODO: sync this with systemd.enableEmergencyMode
      "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
    ];

    loader = {
      timeout = mkDefault 1;

      grub = {
        enable = mkDefault (!config.boot.loader.systemd-boot.enable);
        configurationLimit = mkDefault 8;
        splashImage = null; # I want all the text
        zfsSupport = mkDefault true;
        useOSProber = mkDefault true;
        efiSupport = mkDefault true;
        efiInstallAsRemovable = mkDefault false;
      };

      systemd-boot = {
        # Need to run nixos-rebuild switch --install-bootloader the first time:
        # https://github.com/NixOS/nixpkgs/issues/201677
        enable = mkDefault true;
        configurationLimit = mkDefault 8;
        consoleMode = mkDefault "max";
      };

      efi.canTouchEfiVariables = mkDefault true;
    };
  };
}
