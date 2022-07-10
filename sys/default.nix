{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sys;
in
{
  imports = [
    ./graphical
    ./zfs

    ./boot.nix
    ./gaming.nix
    ./hardware.nix
    ./kubernetes.nix
    ./lib.nix
    ./maintenance.nix
    ./pkgs.nix
    ./secrets.nix
    ./wireless.nix
  ];

  options.sys = {
    user = mkOption {
      description = "The main user.";
      type = types.nonEmptyStr;
      default = "david";
    };
  };

  config = {
    ###################################################
    # Configs that don't warrent their own module yet #
    ###################################################

    # Binary caches
    nix = {
      settings = {
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };

    # Docker
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
    };

    # Timezone
    time.timeZone = "America/Los_Angeles";
    services.geoclue2 = {
      enable = true;

      appConfig = {
        "gammastep" = {
          isAllowed = true;
          isSystem = false;
          users = [ "1000" ];
        };
      };
    };

    # Users
    users.mutableUsers = false;
    users.users = {
      root.hashedPassword = "$6$0/6kZLj/YlKMK7c5$eW4UjS1OE6OtEt9DI6JoeUkc8xi3eLDE2xc4/nD50L8NPYU7m5QpCxPVAYLF2t.hw76Z5/LR7uJztN8fjDVqq.";

      "${cfg.user}" = {
        isNormalUser = true;
        hashedPassword = "$6$8xGwl/pOyfkTn2pB$s2A1K5yORHrtLa.xKkuHIhgzVK.ERZT6IwMLJhDS9kEJYGhWbulm0JUTEckC1ySPoZ9ebTT9Vg/ZC6tBE2RZg.";
        createHome = true;
        shell = pkgs.fish;
        extraGroups = [
          "wheel"
          "docker"
          "audio"
          "video"
        ];

        openssh.authorizedKeys.keys = [
          # TODO: store these in git and pass in/reference directly?
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMXnf0eYbX+aFIdf2ijIeJsVcDwXwgxV4u4e2PjLKll6 david@pavil"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgFADH+64EO9XCSdeHdAQug7UPbXsoqehE2Qwxdj5Sn david@nebula"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAMKrdfKLsS0zIquQL+d8Z+YCpm2v2WQVnYi39iKc8a6 david@cuttlefish"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQy90y+nSJJfVJ4f+SKyg55lhgMTp30+UKlNXWiS3/Q david@bitwarden"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEnaSRCBwX5kziBBeMwHLoS2Pqgl2qY1EvaqT43YWPKq david@pixie"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDTVNg1i4YDsLVpaRlN4xnllBaBFCy35ESHrerhBIV3H david@ace"
        ];
      };
    };

    # Kernel
    boot.kernelPackages = mkDefault pkgs.linuxKernel.packages.linux_zen;

    # Networking
    networking.dhcpcd.wait = mkDefault "background";
    networking.firewall = {
      allowPing = true;
      pingLimit = "--limit 1/second --limit-burst 10";
    };

    services.tailscale.enable = true;
    services.openssh.enable = true;

    # If set to the default (true), the firewall can break some tailscale and kubernetes configs
    networking.firewall.checkReversePath = "loose";

    # Shells
    environment.binsh = "${pkgs.dash}/bin/dash";
    programs.fish.enable = true;
    environment.shells = [ pkgs.fish ];

    # Packages
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs // cfg.pkgs; [
      # Terminal
      fish
      tmux
      starship
      zoxide

      # Utils
      vim
      nodejs # Vim plugins
      curl
      ripgrep
      lshw
      yadm
      pv

      # Development
      git
      cargo
      qemu_kvm
      OVMF
      libvirt
      clang # C compiler
      jq
      yq
      rnix-lsp # Nix language server
      nixpkgs-fmt

      # System utils
      lsof
      pciutils # lspci
      gptfdisk # Disk partitioning (sgdisk)

      # NixOS secrets
      sops
      age
      ssh-to-age

      # Other
      flavours # Themes
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05"; # Did you read the comment?
  };
}
