{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sys;
in
{
  imports = [
    ./graphical/default.nix
    ./zfs

    ./boot.nix
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

    # Main user
    users.users = {
      "${cfg.user}" = {
        isNormalUser = true;
        createHome = true;
        extraGroups = [
          "wheel"
          "docker"
          "audio"
          "video"
        ];
        hashedPassword = "$6$HMrRhU.Z6Rrr5aYX$AUI.Vo0pe7r/JQ3hEBKH69KV8OeddPJS8EC/9YhSOuAgNTKsmX0aoMfdkitCHdeazXuP2eCBEF5IuFgNFeagS0";
        shell = pkgs.fish;
      };
    };

    # Kernel
    boot.kernelPackages = pkgs.linuxPackages_5_17;

    # Networking
    networking.dhcpcd.wait = "background";

    # SSH
    services.openssh.enable = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

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

      # Development
      git
      cargo
      qemu_kvm
      OVMF
      # clang # Not sure why I need this?

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
