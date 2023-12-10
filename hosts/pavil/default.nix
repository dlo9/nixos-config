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
      config.hosts.pixie.ssh-key.pub
    ];

    environment.etc = {
      "/etc/ssh/ssh_host_ed25519_key.pub" = {
        text = config.hosts.${hostname}.host-ssh-key.pub;
        mode = "0644";
      };
    };

    # Users
    home-manager.users.david = import ./home.nix;

    boot.loader.grub.mirroredBoots = [
      {
        devices = ["nodev"];
        efiSysMountPoint = "/boot/efi";
        path = "/boot/efi/EFI";
      }
    ];

    boot.initrd.availableKernelModules = ["r8152"];

    # Bluetooth
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    # Enable A2DP Sink: https://nixos.wiki/wiki/Bluetooth
    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };

    environment.systemPackages = with pkgs; [
      virt-manager

      # ADB fire tablet stuff
      #gnome.zenity

      # Backups
      kopia

      (appimageTools.wrapType2 {
        name = "kopia-ui";
        src = fetchurl {
          url = "https://github.com/kopia/kopia/releases/download/v0.12.1/KopiaUI-0.12.1.AppImage";
          sha256 = "sha256-Kc7ylkXuvD+E6YRe52F1gJqoaAGwQkm/3D91q43P6gU=";
        };
      })
    ];

    # zrepl_switch to new bluetooth devices
    hardware.pulseaudio.extraConfig = "
      load-module module-switch-on-connect
    ";

    zrepl = {
      replicateTo = "cuttlefish.dlo9.github.beta.tailscale.net:1111";

      filesystems = {
        "<" = "long";
        "pool/home/david/Downloads<" = "short";
        "pool/home/david/.cache<" = "local";
        "pool/home/david/code<" = "local";
        "pool/nixos/nix<" = "local";
        "pool/games<" = "local";
        "pool/reserved<" = "local";
      };
    };
  };
}
