{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.sys;
in {
  imports = [
    ./boot
    ./graphical
    ./networking
    ./secrets
    ./zfs

    ./development.nix
    ./gaming.nix
    ./hardware.nix
    ./kubernetes.nix
    ./maintenance.nix
  ];

  # Top-level configuration options
  options.sys = {
    user = mkOption {
      description = "The main user.";
      type = types.nonEmptyStr;
      default = "david";
    };

    low-power = mkEnableOption "low power mode" // {default = false;};
  };

  config = {
    ###################################################
    # Configs that don't warrent their own module yet #
    ###################################################

    # Binary caches
    nix = {
      settings = {
        substituters =
          [
            # Default priority is 50, lower number is higher priority
            "https://cache.nixos.org?priority=50"
            "https://nix-community.cachix.org?priority=50"
            "https://cuda-maintainers.cachix.org?priority=60"
            "daemon?priority=10"
          ]
          ++ lib.optional (!config.services.nix-serve.enable) "https://nix-serve.sigpanic.com?priority=100";

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-serve.sigpanic.com:fp2dLidIBUYvB1SgcAAfYIaxIvzffQzMJ5nd/jZ+hww="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        ];
      };

      # Use cuttlefish as a remote builder
      buildMachines = mkIf cfg.low-power [
        {
          hostName = "cuttlefish";
          systems = ["x86_64-linux" "aarch64-linux"];

          maxJobs = 4;
          speedFactor = 1;
          supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
          mandatoryFeatures = [];
        }
      ];

      distributedBuilds = true;

      extraOptions = ''
        builders-use-substitutes = true
        experimental-features = nix-command flakes
      '';
    };

    # Enable zram
    #zramSwap.enable = true;

    # Docker
    virtualisation.docker = {
      enable = mkDefault true;
      enableOnBoot = true;
    };

    virtualisation.podman = {
      enable = false;
      dockerCompat = true;
      dockerSocket.enable = true;
    };

    # Timezone
    services.localtimed.enable = true;

    # Location services
    services.geoclue2 = {
      enable = true;

      appConfig = {
        "gammastep" = {
          isAllowed = true;
          isSystem = false;
          users = ["1000"];
        };
      };
    };

    # Users
    users.mutableUsers = false;
    users.users = {
      root.hashedPassword = "$6$0/6kZLj/YlKMK7c5$eW4UjS1OE6OtEt9DI6JoeUkc8xi3eLDE2xc4/nD50L8NPYU7m5QpCxPVAYLF2t.hw76Z5/LR7uJztN8fjDVqq.";

      "${cfg.user}" = {
        uid = 1000;
        isNormalUser = true;
        hashedPassword = "$6$8xGwl/pOyfkTn2pB$s2A1K5yORHrtLa.xKkuHIhgzVK.ERZT6IwMLJhDS9kEJYGhWbulm0JUTEckC1ySPoZ9ebTT9Vg/ZC6tBE2RZg.";
        createHome = true;
        shell = pkgs.fish;
        extraGroups = [
          "wheel"
          "docker"
          "podman"
          "audio"
          "video"
          "adbusers" # Android ADB
          "scanner" # Scanning
          "lp" # Printing
        ];
      };
    };

    # Shells
    environment.binsh = "${pkgs.dash}/bin/dash";
    programs.fish.enable = true;
    environment.shells = [pkgs.fish];

    # Packages
    environment.systemPackages = with pkgs // cfg.pkgs; [
      # Terminal
      fish

      # Linux utils
      vim
      nodejs # Vim plugins
      curl
      lshw
      file

      # Nix utils
      nix-diff
      nix-tree
      rnix-lsp # Nix language server
      nixpkgs-fmt

      # System utils
      lsof
      pciutils # lspci
      gptfdisk # Disk partitioning (sgdisk)
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
