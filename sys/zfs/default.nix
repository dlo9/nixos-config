{ config, pkgs, lib, utils, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.zfs;
in
{
  options = {
    # This configures zfs datasets to be managed by zfs utilities after boot as opposed to Nix. These are the recommended options
    # in the Nix ZFS wiki, and so this automatically adds them so that hardware config doesn't need to be modified.
    fileSystems = with types; mkOption {
      type = attrsOf (submodule ({ name, config, ... }: {
        options.zfsUtils = mkOption {
          description = "Let zfsutils manage the mount. The option is ignored if the filesystem type is not ZFS or it's the root mount.";
          type = bool;
          default = cfg.enable;

          # When visible, it triggers a build of the nixos man pages with each rebuild (which takes a *long* time).
          visible = false;
        };

        # Any filesystems marked "neededForBoot" need to have mountpoint=legacy since initrd will mount them manually:
        # https://search.nixos.org/options?channel=22.11&show=fileSystems.%3Cname%3E.neededForBoot
        config.options = mkIf (config.zfsUtils && config.fsType == "zfs" && !(builtins.elem name utils.pathsNeededForBoot)) [
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
    # Kernel
    # TODO: change back once >= 6.2: https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/zfs/stable.nix#L17
    #boot.kernelPackages = mkIf cfg.kernel (mkDefault config.boot.zfs.package.latestCompatibleLinuxPackages);
    boot.kernelPackages = mkDefault pkgs.kernel.linuxKernel.packages.linux_6_3;

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
    ];

    # Unlock ZFS with SSH at boot
    boot.initrd = {
      # supportedFilesystems = [ config.fileSystems."/boot/efi".fsType ];
      # systemd.mounts = [{
      #   what = config.fileSystems."/boot/efi".device;
      #   type = config.fileSystems."/boot/efi".fsType;
      #   where = "/boot/efi";
      # }];

      # systemd.services.zfs-autoload =
      #   let
      #     pool-name = "pool";
      #   in
      #   {
      #     requires = [
      #       "boot-efi.mount"
      #       "systemd-udev-settle.service"
      #     ];

      #     after = [
      #       "boot-efi.mount"
      #       "systemd-udev-settle.service"
      #       "systemd-modules-load.service"
      #     ];

      #     # Name comes from initrd creation: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/tasks/filesystems/zfs.nix
      #     wantedBy = [ "zfs-import-${pool-name}.service" ];
      #     before = [ "zfs-import-${pool-name}.service" ];

      #     unitConfig.DefaultDependencies = "no";

      #     serviceConfig = {
      #       Type = "oneshot";
      #       RemainAfterExit = true;
      #     };

      #     script = ''
      #       if [[ -d /boot/efi/zfs-keys ]]; then
      #         # TODO: doesn't work for filesystems since they contain /
      #         for path in /boot/efi/zfs-keys/*; do
      #           filesystem="$(basename "$path")"
      #           echo "Auto-importing key for $filesystem from $path"
      #           zfs load-key -L "$path" "$filesystem"

      #           #rm "$path"
      #         done
      #       fi
      #     '';
      #   };

      systemd.contents = {
        "/etc/profile".text = ''
          # Only execute this file once per shell.
          if [ -n "$__ETC_PROFILE_SOURCED" ]; then return; fi
          __ETC_PROFILE_SOURCED=1

          # Prevent this file from being sourced by interactive non-login child shells.
          export __ETC_PROFILE_DONE=1

          # Complete any password prompts (e.g. for unlocking disks)
          systemd-tty-ask-password-agent --query
        '';
      };

      # SSH uses the host root key. This exposes the key in initrd, which is okay only because root login is disabled
      # after the system is booted
      network.ssh = {
        enable = true;
        hostKeys = [ /run/secrets/ssh-keys/host/ed25519 ];
        authorizedKeys = config.users.users.${sysCfg.user}.openssh.authorizedKeys.keys;
      };
    };

    # Setup mail for ZFS notifications
    services.postfix = {
      enable = true;
      domain = "sigpanic.com";

      # Fastmail relay
      # There MUST be authentication files placed at `smtp_sasl_password_maps` with the following contents:
      # [smtp.fastmail.com]:465 username:password
      #
      # Send a test mail: `echo "test mail" | sendmail user@domain.com`
      # Check the mail queue: `mailq`
      # Try resending queued mail: `sendmail -q`
      # Check for errors: `systemctl status postfix`
      relayHost = "smtp.fastmail.com";
      relayPort = 465;
      mapFiles = {
        "postfix-auth" = config.sops.secrets.postfix-auth.path;
      };

      config = {
        smtp_sasl_auth_enable = true;
        smtp_sasl_password_maps = "hash:/var/lib/postfix/conf/postfix-auth";
        smtp_sasl_security_options = "noanonymous";
        smtp_use_tls = true;
        smtp_tls_wrappermode = true;
        smtp_tls_security_level = "encrypt";
      };
    };

    sops.secrets.postfix-auth = { };
    services.zfs.zed = {
      settings = {
        ZED_DEBUG_LOG = "/tmp/zed.debug.log";

        ZED_EMAIL_ADDR = [ "if_nas@fastmail.com" ];
        ZED_EMAIL_PROG = "sendmail";
        ZED_EMAIL_OPTS = "'@ADDRESS@'";

        ZED_NOTIFY_INTERVAL_SECS = 3600;
        ZED_NOTIFY_VERBOSE = true;

        ZED_USE_ENCLOSURE_LEDS = true;
        ZED_SCRUB_AFTER_RESILVER = false;
      };
    };
  };
}
