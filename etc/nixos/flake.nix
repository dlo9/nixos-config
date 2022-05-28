{
  inputs = {
    # Path types: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#types

    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11-small;

    # Secrets management
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Theming
    # A decent alternative (can generate color from picture): https://git.sr.ht/~misterio/nix-colors
    base16.url = github:SenchoPens/base16.nix;
    base16.inputs.nixpkgs.follows = "nixpkgs";

    # Main theme
    # https://github.com/chriskempson/base16#scheme-repositories
    base16-atelier = {
      url = github:atelierbram/base16-atelier-schemes;
      flake = false;
    };

    base16-unclaimed = {
      url = github:chriskempson/base16-unclaimed-schemes;
      flake = false;
    };

    # Theme templates
    # https://github.com/chriskempson/base16#template-repositories
    base16-shell = {
      url = github:chriskempson/base16-shell;
      flake = false;
    };

    base16-alacritty = {
      url = github:aarowill/base16-alacritty;
      flake = false;
    };

    base16-mako = {
      url = github:Eluminae/base16-mako;
      flake = false;
    };

    base16-wofi = {
      url = https://git.sr.ht/~knezi/base16-wofi/archive/v1.0.tar.gz;
      flake = false;
    };

    base16-waybar = {
      url = github:mnussbaum/base16-waybar;
      flake = false;
    };

    base16-sway = {
      url = github:rkubosz/base16-sway;
      flake = false;
    };

    base16-gtk = {
      url = github:Misterio77/base16-gtk-flatcolor;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      buildSystem = (hostName: system: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            # Include configuration for nixFlakes, or else everything breaks after switching
            ./configuration.nix

            # Overlays-module makes "pkgs.unstable" available in configuration.nix
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    system = prev.system;
                    config.allowUnfree = true;
                  };
                })
              ];
            })

            # Hardware config
            ./hardware/${hostName}.nix

            # Set hostname, so that it's not copied elsewhere
            { networking.hostName = hostName; }

            # Secrets management
            inputs.sops-nix.nixosModules.sops

            # Custom system modules
            ./sys

            # Home-manager configuration
            # https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
            home-manager.nixosModules.home-manager
            ({ config, ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.david = import ./home.nix;

              # Pass extra arguments to home.nix
              home-manager.extraSpecialArgs = {
                inherit inputs;
                sysCfg = config.sys;
              };
            })
          ] ++ modules;

          # Pass extra arguments to modules
          # specialArgs = {
          #   inherit inputs;
          # };
        }
      );
    in
    {
      nixosConfigurations = with nixpkgs.lib; {
        pavil = buildSystem "pavil" "x86_64-linux" [
          ({ config, ... }: {
            networking.interfaces.wlo1.useDHCP = true;
            boot.loader.grub.mirroredBoots = [
              { devices = [ "nodev" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
            ];

            sys.kubernetes.enable = true;
          })
        ];

        ace = buildSystem "ace" "x86_64-linux" [
          ({ config, ... }: {
            boot.loader.grub.mirroredBoots = [
              { devices = [ "/dev/disk/by-id/ata-KINGSTON_SNS4151S332G_50026B724500626D" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
            ];
          })
        ];

        cuttlefish = buildSystem "cuttlefish" "x86_64-linux" [
          ({ config, ... }: {
            networking.interfaces.enp2s0.useDHCP = true;

            # Must load network module on boot for SSH access
            # lspci -v | grep -iA8 'network\|ethernet'
            boot.initrd.availableKernelModules = [ "r8169" ];
            boot.loader.grub.mirroredBoots = [
              # TODO: add disk for legacy boot
              { devices = [ "nodev" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
            ];

            # GPU
            services.xserver.videoDrivers = [ "nvidia" ];
          })
        ];

        # Build the VM with:
        # sudo nixos-rebuild --flake /etc/nixos#vm build-vm
        vm = buildSystem "vm" "x86_64-linux" [
          ({ config, ... }: {
            sys = {
              #graphical.enable = false;
              #zfs.enable = false;
              #boot.enable = false;
              kubernetes.enable = true;
              #maintenance.enable = false;
              #secrets.enable = false;
              #wireless.enable = false;
            };
          })
        ];
      };
    };
}
