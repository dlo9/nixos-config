{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11-small";

    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs:
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
            ({ config, ... }: { networking.hostName = hostName; })

            # Secrets management
            inputs.sops-nix.nixosModules.sops

            # Custom system modules
            ./sys
          ] ++ modules;
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
