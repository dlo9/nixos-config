{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    sdImage = {
      compressImage = false;
      populateRootCommands = ''
        mkdir ./files/etc
        cp -r ${/etc/nixos} ./files/etc/nixos

        # TODO: sops secret
        mkdir ./files/var
        cp ${/tmp/sops-age-keys-rpi3.txt} ./files/var/sops-age-keys.txt
      '';
    };

    # Enable audio
    sound.enable = true;
    services.pulseaudio.enable = true;

    boot.loader.raspberryPi.firmwareConfig = ''
      dtparam=audio=on
    '';

    # Enable zram
    zramSwap.enable = true;

    # Enable swapfile
    swapDevices = [
      {
        device = "/var/swapfile";
        size = 4096;
        randomEncryption = true;
      }
    ];

    sys = {
      development.enable = false;
      gaming.enable = false;
      graphical.enable = false;
      zfs.enable = false;
    };

    virtualisation.docker.enable = false;
    nix.distributedBuilds = true;

    # Allow IP forwarding for tailscale subnets
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
