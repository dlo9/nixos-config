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
        # Include configuration for nixFlakes, or else everything breaks after switching
        ./configuration.nix

        # Overlays-module makes "pkgs.unstable" available in configuration.nix
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })

        # Secrets management
        inputs.sops-nix.nixosModules.sops

        # Custom system modules
        ./sys
      ];
    in
    {
      nixosConfigurations.pavil = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Hardware config
          ./hardware/pavil.nix

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
        ] ++ common-modules;
      };

      nixosConfigurations.ace = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Hardware config
          ./hardware/ace.nix

          ({ config, ... }: {
            # Should be random for each host to ensure pool doesn't replace root on a different host
            # tr -dc 0-9a-f < /dev/urandom | head -c 8
            networking = {
              hostName = "ace";
              # substring 0 8 (hashString sha256 networking.hostName)
              hostId = "d83696f2";
            };

            boot.loader.grub.mirroredBoots = [
              { devices = [ "/dev/disk/by-id/ata-KINGSTON_SNS4151S332G_50026B724500626D" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
            ];
          })
        ] ++ common-modules;
      };
    };
}
