{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
with lib; {
  imports = [
    ./docker
    ./hardware.nix
    ./users.nix
    ./network.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-disable
    inputs.nixos-hardware.nixosModules.common-hidpi
    ./services
    ./virtualization.nix
    #./vnc.nix
    ./webdav.nix
    ./zrepl.nix
  ];

  config = {
    # Ues overlay2 Docker storage driver for better performance. For this to work,
    # /var/lib/docker/overlay2 MUST be a non-zfs mount (e.g., ext4 zvol)
    # Remove this when OpenZFS has added overlay support in 2.2: https://github.com/openzfs/zfs/pull/9414
    virtualisation.docker.daemon.settings.storage-driver = "overlay2";

    fileSystems."/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs".options = ["nofail"];
    fileSystems."/var/lib/docker/overlay2".options = ["nofail"];

    boot = {
      # Sensors from `sudo sensors-detect --auto; cat /etc/sysconfig/lm_sensors; sudo rm /etc/sysconfig/lm_sensors`
      kernelModules = ["nct6775"];

      zfs.requestEncryptionCredentials = [
        "fast"
        "slow"
      ];

      initrd.supportedFilesystems = ["ext4"];

      # Must load network module on boot for SSH access
      # lspci -v | grep -iA8 'network\|ethernet'
      initrd.availableKernelModules = ["r8169"];
      loader.grub.mirroredBoots = [
        {
          devices = ["/dev/disk/by-id/nvme-CT1000P5SSD8_21242FA1384E"];
          efiSysMountPoint = "/boot/efi0";
          path = "/boot/efi0/EFI";
        }
        {
          devices = ["/dev/disk/by-id/nvme-CT1000P5SSD8_21242FA19AD2"];
          efiSysMountPoint = "/boot/efi1";
          path = "/boot/efi1/EFI";
        }
      ];
    };

    # GPUs
    # See GPUs/sDRM/Render devices with:
    # drm_info -j | jq 'with_entries(.value |= .driver.desc)'
    # ls -l /sys/class/drm/renderD*/device/driver

    # Nvidia GPU
    #services.xserver.videoDrivers = [ "nvidia" ];
    #hardware.nvidia.nvidiaPersistenced = true;

    # Intel GPU
    # nixpkgs.config.packageOverrides = pkgs: {
    #   vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    # };

    # hardware.opengl = {
    #   enable = true;
    #   extraPackages = with pkgs; [
    #     intel-media-driver
    #     vaapiIntel
    #     vaapiVdpau
    #     libvdpau-va-gl
    #     intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    #   ];
    # };

    sys = {
      kubernetes.enable = true;
      #maintenance.autoUpgrade = true;
    };

    boot.blacklistedKernelModules = ["nouveau"];

    environment.systemPackages = with pkgs; [
      # Intel utilization: intel_gpu_top
      intel-gpu-tools
    ];

    # Generate a new (invalid) config: `sudo pwmconfig`
    # View current fan speeds: `sensors | rg fan | rg -v ' 0 RPM'`
    # View current PWM values: `cat /sys/class/hwmon/hwmon5/pwm1`
    # Turn off (almost) all fans:
    # for i in (seq 1 7); echo 0 | sudo tee /sys/class/hwmon/hwmon5/pwm$i; end
    hardware.fancontrol = {
      enable = false;
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

    # Nix cache
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
    networking.firewall.interfaces.mynet.allowedTCPPorts = [7681];
    services.ttyd = {
      enable = true;
      port = 7681;
      interface = "mynet";
      clientOptions = {
        fontFamily = config.font.family;
        fontSize = builtins.toString config.font.size;
      };
    };
  };
}
