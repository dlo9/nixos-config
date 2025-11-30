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
      config.hosts.interchanged.david-ssh-key.pub

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
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

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

    # Enable remote aarch64 builds
    home-manager.users.root.home.stateVersion = "25.05";
    home-manager.users.root.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks.interchange-linux = {
        identitiesOnly = true;
        identityFile = config.sops.secrets.host-ssh-key.path;
        user = "builder";
        hostname = "interchanged";
        port = 31022;
      };

      matchBlocks.interchange-darwin = {
        identitiesOnly = true;
        identityFile = config.sops.secrets.host-ssh-key.path;
        user = "nix-remote";
        hostname = "interchanged";
      };
    };

    # Test with:
    #   nix build nixpkgs#hello --builders '@/etc/nix/machines' -L --max-jobs 0 --system aarch64-linux --rebuild
    #   nix build nixpkgs#hello --builders 'ssh-ng://interchange-linux aarch64-linux' -L --max-jobs 0 --system aarch64-linux --rebuild
    #   nix build nixpkgs#hello --builders 'ssh-ng://interchange-darwin?remote-program=/nix/var/nix/profiles/default/bin/nix-store aarch64-darwin' -L --max-jobs 0 --system aarch64-darwin --rebuild
    nix.buildMachines = [
      {
        hostName = "interchange-darwin?remote-program=/nix/var/nix/profiles/default/bin/nix-store";
        #sshUser = "nix-remote";
        #sshKey = config.sops.secrets.host-ssh-key.path;
        publicHostKey = builtins.readFile (pkgs.runCommandLocal "base64-key" {} ''
          printf "%s" '${config.hosts.interchanged.host-ssh-key.pub}' | ${pkgs.coreutils-full}/bin/base64 -w0 > $out
        '');

        protocol = "ssh";

        systems = [ "aarch64-darwin" ];

        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }

      {
        hostName = "interchange-linux";

        # TODO: this doesn't work (maybe because of RSA keys?), currently relying on non-declaritive known-hosts instead
        # Hard-coded: https://github.com/nix-darwin/nix-darwin/blob/e2b82ebd0f990a5d1b68fcc761b3d6383c86ccfd/modules/nix/linux-builder.nix#L227C26-L227C150
        #publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpCV2N4Yi9CbGFxdDFhdU90RStGOFFVV3JVb3RpQzVxQkorVXVFV2RWQ2Igcm9vdEBuaXhvcwo=";

        protocol = "ssh-ng";

        systems = [ "aarch64-linux" ];

        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
