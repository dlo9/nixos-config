{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:
with lib; {
  imports = [
    ./hardware
  ];

  config = {
    graphical.enable = true;
    developer-tools.enable = true;
    gaming.enable = true;

    # SSH config
    users.users.david.openssh.authorizedKeys.keys = [
      config.hosts.bitwarden.ssh-key.pub
      config.hosts.pixie.host-ssh-key.pub
      config.hosts.cuttlefish.david-ssh-key.pub # deploy-rs
    ];

    environment.etc = {
      "/etc/ssh/ssh_host_ed25519_key.pub" = {
        text = config.hosts.${hostname}.host-ssh-key.pub;
        mode = "0644";
      };
    };

    boot.binfmt.emulatedSystems = [
      "aarch64-linux"
    ];

    # Users
    home-manager.users.david = import ./home.nix;

    boot.initrd.availableKernelModules = ["r8152"];

    # Bluetooth
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    nix.distributedBuilds = true;

    # zrepl_switch to new bluetooth devices
    services.pulseaudio.extraConfig = "
      load-module module-switch-on-connect
    ";

    # Plasma
    services.desktopManager.plasma6.enable = false;

    zrepl = {
      remote = "cuttlefish.fairy-koi.ts.net:1111";

      filesystems = {
        "<".both = "year";
        "fast/home/david/Downloads<".both = "week";
        "fast/home/david/.cache<".local = "week";
        "fast/home/david/code<".local = "week";
        "fast/nixos/nix<".local = "week";
        "fast/games<".local = "week";
        "fast/reserved<" = {};
      };
    };
  };
}
