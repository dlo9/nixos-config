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
    ];

    environment.etc = {
      "/etc/ssh/ssh_host_ed25519_key.pub" = {
        text = config.hosts.${hostname}.host-ssh-key.pub;
        mode = "0644";
      };
    };

    # Users
    home-manager.users.david = import ./home.nix;

    boot.initrd.availableKernelModules = ["r8152"];

    # Bluetooth
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    # environment.systemPackages = with pkgs; [
    #   virt-manager
    # ];

    # zrepl_switch to new bluetooth devices
    hardware.pulseaudio.extraConfig = "
      load-module module-switch-on-connect
    ";

    zrepl = {
      remote = "cuttlefish.dlo9.github.beta.tailscale.net:1111";

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
