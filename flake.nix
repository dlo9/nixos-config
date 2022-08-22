{
  inputs = {
    # Path types: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#types

    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    # TODO: revert back to 22.05-small once [submoduleWith](https://github.com/NixOS/nixpkgs/blob/6c32b75a332a5f6ca08a36d1e7f0e9d38ec39d19/lib/types.nix#L569)
    # has a description field. This is due to changes in home-manager which I can't revert
    #nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05-small;
    #nixpkgs.url = github:NixOS/nixpkgs/nixos-test-staging;
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    # Secrets management
    sops-nix.url = github:Mic92/sops-nix;
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    # FUTURE: set to a specific release, or else changes can become out of sync with nixos
    #home-manager.url = github:nix-community/home-manager/release-22.05;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mobile-nixos = {
      url = github:NixOS/mobile-nixos;
      flake = false;
    };

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
        let
          hardwareConfig = ./hardware/${hostName}.nix;
          hostConfig = ./hosts/${hostName};
        in
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            # Include configuration for nixFlakes, or else everything breaks after switching
            ./configuration.nix

            ({ config, pkgs, ... }: {
              # Overlays-module makes "pkgs.unstable" available in configuration.nix
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
            ({ config, pkgs, lib, ... }@args: (lib.optionalAttrs (lib.pathExists hardwareConfig) (import hardwareConfig args)))

            # Host config
            ({ config, pkgs, lib, ... }@args: (lib.optionalAttrs (lib.pathExists hostConfig) (import hostConfig args)))

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
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "home-manager-backup";
                users.david = import ./home;

                # Pass extra arguments to home.nix
                extraSpecialArgs = {
                  inherit inputs;
                  sysCfg = config.sys;
                };
              };
            })
          ] ++ modules;

          # Pass extra arguments to modules
          specialArgs = {
            inherit inputs;
          };
        }
      );
    in
    {
      nixosConfigurations = with nixpkgs.lib; rec {
        pavil = buildSystem "pavil" "x86_64-linux" [
          ({ config, pkgs, ... }: {
            boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
            programs.adb.enable = true;

            networking.interfaces.wlo1.useDHCP = true;

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

            # Auto-switch to new bluetooth devices
            hardware.pulseaudio.extraConfig = "
              load-module module-switch-on-connect
            ";

            boot.loader.grub.mirroredBoots = [
              { devices = [ "nodev" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
            ];

            environment.systemPackages = with pkgs; with config.sys.pkgs; [
              genie-client
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
            boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

            # Ues overlay2 Docker storage driver for better performance. For this to work,
            # /var/lib/docker/overlay2 MUST be a non-zfs mount (e.g., ext4 zvol)
            virtualisation.docker.daemon.settings.storage-driver = "overlay2";

            boot = {
              # Sensors from `sudo sensors-detect`
              kernelModules = [ "coretemp" "nct7904" ];
              kernelPackages = pkgs.linuxPackages_hardened;

              zfs.extraPools = [
                #"slow"
              ];

              zfs.requestEncryptionCredentials = [
                "fast"
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
              maintenance.autoUpgrade = true;
            };

            environment.systemPackages = with pkgs; [
              # Chassis and fan control
              ipmitool
              #ipmicfg
            ];

            powerManagement.cpuFreqGovernor = "powersave";

            # Generate a new (invalid) config: `sudo pwmconfig`
            # View current fan speeds: `sensors | rg fan | rg -v ' 0 RPM'`
            # View current PWM values: `cat /sys/class/hwmon/hwmon5/pwm1`
            hardware.fancontrol = {
              enable = true;
              # Hot core: hwmon0/temp3_input
              # Cool core: hwmon4/temp3_input
              config = ''
                INTERVAL=10
                DEVPATH=hwmon5=devices/pci0000:00/0000:00:1f.3/i2c-2/2-002d
                DEVNAME=hwmon5=nct7904
                FCTEMPS=hwmon5/pwm4=hwmon4/temp3_input hwmon5/pwm3=hwmon4/temp3_input hwmon5/pwm2=hwmon4/temp3_input hwmon5/pwm1=hwmon4/temp3_input
                FCFANS= hwmon5/pwm4=hwmon5/fan6_input  hwmon5/pwm3=hwmon5/fan6_input  hwmon5/pwm2=hwmon5/fan6_input  hwmon5/pwm1=hwmon5/fan6_input
                MINTEMP= hwmon5/pwm4=40  hwmon5/pwm3=40  hwmon5/pwm2=40  hwmon5/pwm1=40
                MAXTEMP= hwmon5/pwm4=80  hwmon5/pwm3=80  hwmon5/pwm2=80  hwmon5/pwm1=80
                MINSTART=hwmon5/pwm4=50  hwmon5/pwm3=50  hwmon5/pwm2=50  hwmon5/pwm1=50
                MINSTOP= hwmon5/pwm4=50  hwmon5/pwm3=50  hwmon5/pwm2=50  hwmon5/pwm1=50
              '';
            };

            # Allow IP forwarding for tailscale subnets
            boot.kernel.sysctl = {
              # Already enabled for kubelet
              #"net.ipv4.ip_forward" = 1;
              "net.ipv6.conf.all.forwarding" = 1;
            };
          })
        ];

        # Build with: `nix build 'path:.#nixosConfigurations.moto-image'`
        # Impure needed to access host paths without putting in the nix store
        moto-image = moto.config.mobile.outputs.android.android-fastboot-images;

        # https://mobile.nixos.org/devices/motorola-potter.html
        # - Test with: nix eval "/etc/nixos#nixosConfigurations.moto.config.system.build.toplevel.drvPath"
        # - Build with: nixos-rebuild build --flake path:///etc/nixos#moto
        moto = buildSystem "moto" "aarch64-linux" [
          ({ ... }: import "${inputs.mobile-nixos}/lib/configuration.nix" { device = "motorola-potter"; })

          ({ config, pkgs, ... }: {

            mobile = {
              adbd.enable = true;

              boot.stage-1 = {
                fbterm.enable = true;

                networking = {
                  enable = true;

                  # These are the defaults, but are here for easy reference
                  IP = "172.16.42.1";
                  hostIP = "172.16.42.2";
                };

                kernel = {
                  allowMissingModules = false;

                  # https://github.com/NixOS/mobile-nixos/pull/506
                  #useNixOSKernel = true;
                };

                shell.shellOnFail = true;
                #ssh.enable = true;
              };
            };

            hardware.firmware = [
              (config.mobile.device.firmware.override {
                modem = ./firmware;
              })
            ];

            sys = {
              kernel = false;
              gaming.enable = false;
              graphical.enable = false;
              zfs.enable = false;
            };

            home-manager.users.david.home.gui.enable = false;

            # This kernel does not support rpfilter
            networking.firewall.checkReversePath = false;
          })
        ];

        # Build with: `nix build --impure 'path:.#nixosConfigurations.rpi3-image'`
        # Impure needed to access host paths without putting in the nix store
        rpi3-image = rpi3.config.system.build.sdImage;
        rpi3 = buildSystem "rpi3" "aarch64-linux" [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ({ ... }: {
            sdImage = {
              compressImage = false;
              populateRootCommands = ''
                mkdir ./files/etc
                cp -r ${/etc/nixos} ./files/etc/nixos

                # TODO: sops secret
                mkdir ./files/var
                cp ${/tmp/sops-age-keys-rpi3.txt} ./files/var/sops-age-keys.txt
              '';
            };
          })

          ({ config, pkgs, ... }: {
            home-manager.users.david.home.gui.enable = false;

            # Enable audio
            sound.enable = true;
            hardware.pulseaudio.enable = true;

            boot.loader.raspberryPi.firmwareConfig = ''
              dtparam=audio=on
            '';

            # Enable zram
            zramSwap.enable = true;

            # Enable swapfile
            swapDevices = [
              {
                device = "/var/swapfile";
                size = 4096;
                randomEncryption = true;
              }
            ];

            sys = {
              development.enable = false;
              gaming.enable = false;
              graphical.enable = false;
              zfs.enable = false;
            };

            virtualisation.docker.enable = false;

            # Allow IP forwarding for tailscale subnets
            boot.kernel.sysctl = {
              "net.ipv4.ip_forward" = 1;
              "net.ipv6.conf.all.forwarding" = 1;
            };

            environment.systemPackages = with pkgs; with config.sys.pkgs; [
              genie-client
            ];
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
