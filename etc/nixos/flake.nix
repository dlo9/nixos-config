{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11-small";

    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs:
    let
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          system = prev.system;
          config.allowUnfree = true;
        };
      };

      common-modules = [
        # Overlays-module makes "pkgs.unstable" available in configuration.nix
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })

        # Secrets management
        inputs.sops-nix.nixosModules.sops

        # Hardware config, should be a symlink to the host hardware config
        ./hardware-configuration.nix
        ./configuration.nix

        # All other configuration
        ./sys
      ];
    in
    {
      nixosConfigurations.pavil = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ config, ... }: {
            # Should be random for each host to ensure pool doesn't replace root on a different host
            # tr -dc 0-9a-f < /dev/urandom | head -c 8
            networking = {
              hostName = "pavil";
              # substring 0 8 (hashString sha256 networking.hostName)
              hostId = "fa305d4a";
            };

            boot.loader.grub.mirroredBoots = [
              { devices = [ "nodev" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
            ];
          })

          #./configuration.nix
          #./hardware-configuration.nix

          # ./lib/printing.nix
          # ./lib/system.nix
          # ./lib/polkit.nix
          # ./lib/networking.nix
          # ./lib/zfs.nix
          # ./lib/zfs-mount-options.nix

        ] ++ common-modules;
      };

      nixosConfigurations.ace = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Overlays-module makes "pkgs.unstable" available in configuration.nix
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })

          ./configuration.nix
          ./hardware-configuration.nix

          ./lib/printing.nix
          ./lib/system.nix
          ./lib/polkit.nix
          ./lib/networking.nix
          ./lib/zfs.nix

          # Secrets management
          inputs.sops-nix.nixosModules.sops
        ];
      };
    };
}

