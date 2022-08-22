{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
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

    services.zrepl = {
      enable = true;
      settings = {
        global = {
          logging = [
            {
              type = "stdout";
              level = "warn";
              format = "human";
              time = true;
              color = true;
            }
          ];

          monitoring = [
            {
              type = "prometheus";
              listen = ":9091";
              listen_freebind = true;
            }
          ];
        };

        jobs = [
          {
            name = "pool snapshot";
            type = "snap";
            filesystems = {
              # Root enables
              "fast<" = true;
              "slow<" = true;

              # Disable replicated datasets, trash
              "slow/abyss<" = false;
              "slow/backup/drywell<" = false;
              "slow/trash<" = false;
            };

            snapshotting = {
              type = "periodic";
              interval = "15m";
              prefix = "zrepl_";
            };

            pruning = {
              keep = [
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 24x1h | 31x1d | 12x30d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  regex = "^manual.*";
                }
              ];
            };
          }

          #{
          #  name = "drywell replication";
          #  type = "pull";
          #  root_fs = "slow/backup/drywell";
          #  interval = "24h";

          #  connect = {
          #    type = "ssh+stdinserver";
          #    host = "drywell.sigpanic.com";
          #    user = "root";
          #    port = 22;

          #    # TODO: use a real key
          #    identity_file: "/etc/zrepl/ssh/identity/id_rsa";
          #  };

          #  pruning = {
          #    keep_sender = [
          #      { type = "not_replicated"; }
          #      {
          #        type = "grid";
          #        grid = "1x1h(keep=all) | 24x1h | 31x1d | 12x30d";
          #        regex = "^auto-.*";
          #      }
          #      {
          #        type = "regex";
          #        regex = "^manual.*";
          #      }
          #      {
          #        type = "regex";
          #        regex = ".*";
          #      }
          #    ];

          #    keep_receiver = [
          #      {
          #        type = "grid";
          #        grid = "1x1h(keep=all) | 24x1h | 31x1d | 12x30d";
          #        regex = "^auto-.*";
          #      }
          #      {
          #        type = "regex";
          #        regex = "^manual.*";
          #      }
          #      {
          #        type = "regex";
          #        regex = ".*";
          #      }
          #    ];
          #  };
          #}
        ];
      };
    };
  };
}
