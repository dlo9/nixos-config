{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.sys;
in
{
  imports = [
    ./graphical
    ./networking
    ./secrets
    ./zfs

    ./boot.nix
    ./development.nix
    ./gaming.nix
    ./hardware.nix
    ./kubernetes.nix
    ./lib.nix
    ./maintenance.nix
    ./pkgs.nix
  ];

  # Top-level configuration options
  options.sys = {
    user = mkOption {
      description = "The main user.";
      type = types.nonEmptyStr;
      default = "david";
    };

    kernel = mkEnableOption "set the kernel" // { default = true; };
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

        ] ++ lib.optional (!config.services.nix-serve.enable) "https://nix-serve.sigpanic.com";
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-serve.sigpanic.com:fp2dLidIBUYvB1SgcAAfYIaxIvzffQzMJ5nd/jZ+hww="
        ];
      };
    };

    nixpkgs.overlays = [
      (final: prev: {
        # Makes "pkgs.unstable" available in configuration.nix
        unstable = import inputs.nixpkgs-unstable {
          system = prev.system;
          config.allowUnfree = true;
        };
      })
    ];

    # Enable zram
    #zramSwap.enable = true;

    # Docker
    virtualisation.docker = {
      enable = mkDefault true;
      enableOnBoot = true;
    };

    # Timezone
    time.timeZone = "America/Los_Angeles";

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
          "adbusers"
        ];
      };
    };

    # Kernel
    boot.kernelPackages = mkIf cfg.kernel (mkDefault pkgs.linuxKernel.packages.linux_zen);

    # Networking
    networking.dhcpcd.wait = mkDefault "background";
    networking.firewall = {
      allowPing = true;
      pingLimit = "--limit 1/second --limit-burst 10";
    };

    services.tailscale.enable = true;
    services.openssh.enable = true;

    # If set to the default (true), the firewall can break some tailscale and kubernetes configs
    networking.firewall.checkReversePath = mkDefault "loose";

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

      # Linux utils
      vim
      nodejs # Vim plugins
      curl
      ripgrep
      lshw
      pv
      p7zip

      # Nix utils
      nix-diff
      nix-tree
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
