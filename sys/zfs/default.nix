{ config, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.zfs;

  zfs-helper = pkgs.writeTextFile {
    name = "zfs-helper";
    executable = true;
    destination = "/bin/zfs-helper";
    text = builtins.readFile ./zfs-helper.sh;
  };

  zfs-helper-ssh-prompt = pkgs.writeTextFile {
    name = "zfs-helper-ssh-prompt";
    text = "zfs-helper onBootPrompt";
  };
in
{
  options = {
    # This configures zfs datasets to be managed by zfs utilities after boot as opposed to Nix. These are the recommended options
    # in the Nix ZFS wiki, and so this automatically adds them so that hardward config doesn't need to be modified.
    fileSystems = with types; mkOption {
      type = attrsOf (submodule ({ name, config, ... }: {
        options.zfsUtils = mkOption {
          description = "Let zfsutils manage the mount. The option is ignored if the filesystem type is not ZFS or it's the root mount.";
          type = bool;
          default = cfg.enable;

          # When visible, it triggers a build of the nixos man pages with each rebuild (which takes a *long* time).
          visible = false;
        };

        config.options = mkIf (config.zfsUtils && config.fsType == "zfs" && name != "/") [
          "zfsutil"
          "X-mount.mkdir"
          "nofail"
        ];
      }));
    };

    sys.zfs = {
      enable = mkEnableOption "ZFS tools" // { default = true; };
    };
  };

  config = mkIf cfg.enable {
    # Derive `hostId`, which must be set for `zpool import`, from hostname
    # If instead it should be static for a host, then generate with `tr -dc 0-9a-f < /dev/urandom | head -c 8`
    networking.hostId = mkDefault (substring 0 8 (builtins.hashString "sha256" config.networking.hostName));

    boot = {
      zfs.devNodes = "/dev/disk/by-id";

      # Hibernation on ZFS can cause corruption
      # Plus, this doesn't work with randomly encrypted swap
      kernelParams = [ "nohibernate" ];
    };

    services.zfs = {
      trim.enable = true;
      autoScrub.enable = true;
      autoScrub.interval = "Sun, 02:00";
    };

    environment.systemPackages = with pkgs; [
      zfs
      zfs-helper
    ];

    # On safe shutdown, save key to file for reboot
    # TODO: enable/disable: https://discourse.nixos.org/t/using-mkif-with-nested-if/5221
    powerManagement.powerDownCommands = "zfs-helper onShutdown";
    systemd.services.zfs-helper-shutdown = {
      description = "Save ZFS keys on scheduled shutdown";
      path = [
        pkgs.mount
        pkgs.umount
      ];

      after = [ "final.target" ];
      wantedBy = [ "final.target" ];

      unitConfig = {
        DefaultDependencies = false;
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${zfs-helper}/bin/zfs-helper onShutdown'';
      };

    };

    # Unlock ZFS with SSH at boot
    # TODO: enable/disable
    boot = {
      initrd.supportedFilesystems = [ "vfat" ];
      initrd.extraFiles = {
        "/root/.profile".source = zfs-helper-ssh-prompt;
      };

      initrd.extraUtilsCommands = ''
        copy_bin_and_libs ${zfs-helper}/bin/zfs-helper
      '';

      initrd.extraUtilsCommandsTest = ''
        $out/bin/zfs-helper version
      '';

      initrd.postDeviceCommands = "zfs-helper onBoot >/dev/null &";

      initrd.network = {
        # Make sure you have added the kernel module for your network driver to `boot.initrd.availableKernelModules`,
        enable = true;
        ssh = {
          enable = true;
          port = 22;

          # Use the RSA key for initrd since ED25519 is used for the host
          hostKeys = [
            # TODO: This doesn't work because of something to do with the initrd /etc mount (I think)
            #/etc/ssh/ssh_host_rsa_key

            # This was manually copied from the path above
            /var/ssh_host_rsa_key
          ];

          # TODO: disable password auth (if not already?)
          authorizedKeys = config.users.users.${sysCfg.user}.openssh.authorizedKeys.keys;
        };
      };
    };
  };
}
