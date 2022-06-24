{
  inputs = {
    # Path types: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#types

    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05-small;

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
              home-manager.users.david = import ./home;

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
          })
        ];

        nebula = buildSystem "nebula" "x86_64-linux" [
          ({ config, ... }: {
            networking.interfaces.enp8s0.useDHCP = true;
            boot.loader.grub.mirroredBoots = [
              { devices = [ "/dev/disk/by-id/nvme-CT1000P5SSD8_21242F9FEFE5" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
            ];
          })
        ];

        ace = buildSystem "ace" "x86_64-linux" [
          ({ config, ... }: {
            boot.loader = {
              efi.canTouchEfiVariables = false;

              grub.mirroredBoots = [
                { devices = [ "/dev/disk/by-id/ata-KINGSTON_SNS4151S332G_50026B724500626D" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
              ];
            };
          })
        ];

        cuttlefish = buildSystem "cuttlefish" "x86_64-linux" [
          ({ config, pkgs, ... }: {
            # TODO: can I enable this and not deploy/block boot i fit's not connected?
            #networking.interfaces.enp5s0f0.useDHCP = true;
            networking.interfaces.enp5s0f1.useDHCP = true;
            #networking.dhcpcd.wait = "background";

            boot = {
              # Sensors from `sudo sensors-detect`
              kernelModules = [ "coretemp" "nct7904" ];

              zfs.extraPools = [
                "slow"
              ];

              # Must load network module on boot for SSH access
              # lspci -v | grep -iA8 'network\|ethernet'
              initrd.availableKernelModules = [ "igb" ];
              loader.grub.mirroredBoots = [
                { devices = [ "/dev/disk/by-id/nvme-CT1000P5SSD8_21242FA1384E" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
                { devices = [ "/dev/disk/by-id/nvme-CT1000P5SSD8_21242FA19AD2" ]; efiSysMountPoint = "/boot/efi1"; path = "/boot/efi1/EFI"; }

                # Also install onto a USB drive, since the motherboard can't boot from NVME
                { devices = [ "/dev/disk/by-id/usb-Lexar_USB_Flash_Drive_046S07AT1V2U6VYA-0:0" ]; efiSysMountPoint = "/boot/efi2"; path = "/boot/efi2/EFI"; }
              ];

              # TODO: don't think I need after install
              # (and now that other boot issues are resolved)
              loader.efi.canTouchEfiVariables = false;
              loader.grub.efiInstallAsRemovable = true;
            };

            # GPU
            services.xserver.videoDrivers = [ "nvidia" ];

            home-manager.users.david.home.gui.enable = false;
            sys = {
              kubernetes.enable = true;
              graphical.enable = false;
            };

            powerManagement.cpuFreqGovernor = "powersave";

            # Generate a new config with `sudo pwmconfig`
            hardware.fancontrol = {
              enable = true;
                #FCFANS= hwmon3/device/pwm2=hwmon3/device/fan7_input+hwmon3/device/fan6_input+hwmon3/device/fan5_input
              # Hot core: hwmon4/temp3_input
              # Cool core: hwmon0/temp3_input
              config = ''
                INTERVAL=10
                DEVPATH=hwmon5=devices/pci0000:00/0000:00:1f.3/i2c-2/2-002d
                DEVNAME=hwmon5=nct7904
                FCTEMPS=hwmon5/pwm4=hwmon4/temp3_input hwmon5/pwm3=hwmon4/temp3_input hwmon5/pwm2=hwmon4/temp3_input hwmon5/pwm1=hwmon4/temp3_input
                #FCTEMPS=hwmon5/pwm4=hwmon0/temp3_input hwmon5/pwm3=hwmon0/temp3_input hwmon5/pwm2=hwmon0/temp3_input hwmon5/pwm1=hwmon0/temp3_input
                FCFANS=hwmon5/pwm4=hwmon5/fan6_input hwmon5/pwm3=hwmon5/fan6_input hwmon5/pwm2=hwmon5/fan6_input hwmon5/pwm1=hwmon5/fan6_input
                MINTEMP=hwmon5/pwm4=30 hwmon5/pwm3=30 hwmon5/pwm2=30 hwmon5/pwm1=30
                MAXTEMP=hwmon5/pwm4=80 hwmon5/pwm3=80 hwmon5/pwm2=80 hwmon5/pwm1=80
                MINSTART=hwmon5/pwm4=150 hwmon5/pwm3=150 hwmon5/pwm2=150 hwmon5/pwm1=150
                MINSTOP=hwmon5/pwm4=0 hwmon5/pwm3=0 hwmon5/pwm2=0 hwmon5/pwm1=100
                MAXPWM=hwmon5/pwm4=q
              '';
            };
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

        # Installer test
        installer = buildSystem "installer" "x86_64-linux" [
          ({ config, ... }: {
            boot.loader = {
              grub.mirroredBoots = [
                { devices = [ "/dev/disk/by-path/virtio-pci-0000:00:04.0" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
                { devices = [ "/dev/disk/by-path/virtio-pci-0000:00:05.0" ]; efiSysMountPoint = "/boot/efi1"; path = "/boot/efi1/EFI"; }
                # TODO: test
                #{ devices = [ "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001" ]; efiSysMountPoint = "/boot/efi/ata-QEMU_HARDDISK_QM00001"; }
                #{ devices = [ "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00002" ]; efiSysMountPoint = "/boot/efi/ata-QEMU_HARDDISK_QM00002"; }
              ];

              # TODO: only for installing
              efi.canTouchEfiVariables = false;
              grub.efiInstallAsRemovable = true;
            };

            services.qemuGuest.enable = true;
            services.spice-vdagentd.enable = true;
            boot.kernelParams = [ "nomodeset" ];
          })
        ];
      };
    };
}
