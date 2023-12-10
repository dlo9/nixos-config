{
  config,
  pkgs,
  lib,
  utils,
  ...
}:
with lib; {
  imports = [
    ./automount.nix
    ./zrepl.nix
  ];

  config = mkIf config.boot.zfs.enabled {
    boot.kernelPackages = mkDefault config.boot.zfs.package.latestCompatibleLinuxPackages;

    # Derive `hostId`, which must be set for `zpool import`, from hostname
    # If instead it should be static for a host, then generate with `tr -dc 0-9a-f < /dev/urandom | head -c 8`
    networking.hostId = mkDefault (substring 0 8 (builtins.hashString "sha256" config.networking.hostName));

    boot = {
      zfs.devNodes = mkDefault "/dev/disk/by-id";

      # Hibernation on ZFS can cause corruption
      # Plus, this doesn't work with randomly encrypted swap
      kernelParams = ["nohibernate"];
    };

    services.zfs = {
      # TODO: only enable when there are ZFS filesystems present
      trim.enable = mkDefault true;
      autoScrub.enable = mkDefault true;
      autoScrub.interval = "Sun, 02:00";
    };

    environment.systemPackages = with pkgs; [
      zfs
    ];

    # Make container snapshotterssuse overlayfs, since autodetection doesn't always work
    virtualisation.containerd.settings.plugins."io.containerd.grpc.v1.cri".containerd.snapshotter = "overlayfs";
    virtualisation.docker.daemon.settings.storage-driver = "overlay2";

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
        enable = mkDefault true;
        hostKeys = [/run/secrets/host-ssh-key];
      };
    };
  };
}
