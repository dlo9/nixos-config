{
  config,
  inputs,
  pkgs,
  lib,
  hostname,
  ...
}:
with lib; {
  imports = [
    ./docker
    ./hardware
    ./services

    ./network.nix
    ./users.nix
    #./virtualization.nix
  ];

  config = {
    # SSH config
    users.users.david.openssh.authorizedKeys.keys = [
      config.hosts.bitwarden.ssh-key.pub
      config.hosts.pixie.host-ssh-key.pub
      config.hosts.pavil.david-ssh-key.pub

      config.hosts.drywell.david-ssh-key.pub # zrepl?
    ];

    environment.etc = {
      "/etc/ssh/ssh_host_ed25519_key.pub" = {
        text = config.hosts.${hostname}.host-ssh-key.pub;
        mode = "0644";
      };
    };

    graphical.enable = true;
    developer-tools.enable = true;
    gaming.enable = true;

    # Bluetooth
    hardware.bluetooth.enable = true;

    # Could also override systemd's DefaultTimeoutStopSec, but other services seem to behave
    systemd.extraConfig = "DefaultTimeoutStopSec=10s";

    fileSystems."/zfs" = {
      device = "fast/zfs";
      fsType = "zfs";
      neededForBoot = true;
    };

    boot = {
      # Sensors from `sudo sensors-detect --auto; cat /etc/sysconfig/lm_sensors; sudo rm /etc/sysconfig/lm_sensors`
      kernelModules = ["nct6775"];

      zfs.extraPools = ["slow"];

      zfs.requestEncryptionCredentials = [
        "fast"
        "slow"
      ];

      # TODO: Why do I need this if I don't have ext4?
      initrd.supportedFilesystems.ext4 = true;

      # Must load network module on boot for SSH access
      # lspci -v | grep -iA8 'network\|ethernet'
      initrd.availableKernelModules = ["r8169"];
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

    # hardware.graphics = {
    #   enable = true;
    #   extraPackages = with pkgs; [
    #     intel-media-driver
    #     vaapiIntel
    #     vaapiVdpau
    #     libvdpau-va-gl
    #     intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    #   ];
    # };

    boot.blacklistedKernelModules = ["nouveau"];

    environment.systemPackages = with pkgs; [
      # Intel utilization: intel_gpu_top
      intel-gpu-tools
      kdePackages.krdp
    ];

    # Plasma
    #services.desktopManager.plasma6.enable = true;
    # https://github.com/sddm/sddm/issues/1768
    #users.users.david.shell = pkgs.bash;

    # Generate a new (invalid) config: `sudo pwmconfig`
    # View current CPU temp: `sensors | rg -A3 k10temp-pci-00c3 | rg -o '[0-9\.]+°C'`
    # View current fan speeds: `sensors | rg fan | rg -v ' 0 RPM'`
    # View current PWM values: `cat /sys/class/hwmon/hwmon3/pwm?`
    # Turn off (almost) all fans:
    # for i in (seq 1 7); echo 0 | sudo tee /sys/class/hwmon/hwmon3/pwm$i; end
    hardware.fancontrol = {
      enable = false;
      config = ''
        INTERVAL=10
        DEVPATH=hwmon3=devices/platform/nct6775.2592 hwmon4=devices/pci0000:00/0000:00:18.3
        DEVNAME=hwmon3=nct6797 hwmon4=k10temp
        FCTEMPS=hwmon3/pwm2=hwmon4/temp1_input hwmon3/pwm3=hwmon4/temp1_input hwmon3/pwm4=hwmon4/temp1_input hwmon3/pwm5=hwmon4/temp1_input hwmon3/pwm6=hwmon4/temp1_input hwmon3/pwm7=hwmon4/temp1_input
        FCFANS= hwmon3/pwm2=hwmon3/fan2_input  hwmon3/pwm3=hwmon3/fan3_input  hwmon3/pwm4=hwmon3/fan4_input  hwmon3/pwm5=hwmon3/fan5_input  hwmon3/pwm6=hwmon3/fan6_input  hwmon3/pwm7=hwmon3/fan7_input
        MINTEMP= hwmon3/pwm2=40  hwmon3/pwm3=40  hwmon3/pwm4=40  hwmon3/pwm5=40  hwmon3/pwm6=40  hwmon3/pwm7=40
        MAXTEMP= hwmon3/pwm2=60  hwmon3/pwm3=60  hwmon3/pwm4=60  hwmon3/pwm5=60  hwmon3/pwm6=60  hwmon3/pwm7=60
        MINSTART=hwmon3/pwm2=100 hwmon3/pwm3=100 hwmon3/pwm4=100 hwmon3/pwm5=100 hwmon3/pwm6=100 hwmon3/pwm7=100
        MINSTOP= hwmon3/pwm2=100 hwmon3/pwm3=100 hwmon3/pwm4=100 hwmon3/pwm5=100 hwmon3/pwm6=100 hwmon3/pwm7=100
      '';
    };

    networking.firewall.allowedTCPPorts = [
      # Authentik: Is this necessary?
      9000

      # Misc testing
      8080
    ];

    # Home assistant's voice assistant uses random UDP ports, which we need to allow
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 0;
        to = 65535;
      }
    ];
  };
}
