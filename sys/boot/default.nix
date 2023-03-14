{ ... }:

{
  imports = [
    ./bootloader.nix
    # Don't enable this!! See file for details
    #./systemd-network.nix
  ];

  config = {
    # Enable systemd in init
    # boot.initrd.systemd.enable = true;

    # Enable emergency access, even with root account locked
    # TODO: sync this with systemd.enableEmergencyMode
    boot.kernelParams = [ "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1" ];
  };
}
