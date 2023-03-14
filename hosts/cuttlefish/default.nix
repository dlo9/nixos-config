{ config, inputs, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
in
{
  imports = [
    ./docker
    ./hardware.nix
    ./samba.nix
    ./users.nix
    inputs.vscode-server.nixosModule
    ./services
    ./virtualization.nix
    ./vnc.nix
    ./webdav.nix
    ./zrepl.nix
  ];

  config = {
    networking = {
      dhcpcd.wait = "if-carrier-up";

      interfaces.lan = {
        # FUTURE: Use a locally administered, unicast address like "02:9e:8d:a6:ea:d5"
        # Only downside is that it won't get the same IP during init and after init
        macAddress = "00:25:90:91:fd:ab";
      };

      bonds = {
        lan = {
          interfaces = [
            "enp5s0f1"
            "enp5s0f0"
          ];

          driverOptions = {
            mode = "balance-rr";
            miimon = "100";
          };
        };
      };
    };

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
        "slowcache"
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
    hardware.nvidia.nvidiaPersistenced = true;

    sys = {
      kubernetes.enable = true;
      #maintenance.autoUpgrade = true;
    };

    environment.systemPackages = with pkgs; [
      # Chassis and fan control
      ipmitool
      #ipmicfg

      # CUDA support
      #cudaPackages.cudatoolkit
      cudaPackages.cutensor
      cudaPackages.cudnn
      nvidia-vaapi-driver

      #sysCfg.pkgs.sunshine
      #sunshine

      # Contains "new" flags for Nvidia GPUs which are in all the docs
      (ffmpeg_5-full.override {
        nv-codec-headers = nv-codec-headers-11;
      })
    ];

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

    # Nix cache
    sops.secrets.nix-serve-private-key = {
      sopsFile = sysCfg.secrets.hostSecretsFile;
    };

    services.nix-serve = {
      enable = true;
      port = 5000;
      openFirewall = true;
      secretKeyFile = config.sops.secrets.nix-serve-private-key.path;
    };

    networking.firewall.allowedTCPPorts = [
      # TODO: is this for prometheus?
      9000

      # Misc testing
      8080
    ];

    # Code Server
    #services.vscode-server.enable = true;

    # Web shell
    # Only accessable from "mynet", which is the k8s node network
    networking.firewall.interfaces.mynet.allowedTCPPorts = [ 7681 ];
    services.ttyd = {
      enable = true;
      port = 7681;
      interface = "mynet";
      clientOptions = {
        fontFamily = "NotoSansMono Nerd Font";
        fontSize = "14";
      };
    };
  };
}
