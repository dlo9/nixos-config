{lib, ...}:
with lib; {
  boot = {
    boot.initrd = {
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
        enable = mkDefault true;
        configurationLimit = mkDefault 8;
        splashImage = null; # I want all the text
        zfsSupport = mkDefault true;
        useOSProber = mkDefault true;
        efiSupport = mkDefault true;
        efiInstallAsRemovable = mkDefault false;
      };

      efi.canTouchEfiVariables = mkDefault true;
    };
  };
}
