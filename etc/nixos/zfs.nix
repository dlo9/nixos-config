# https://nixos.wiki/wiki/ZFS
{ config, pkgs, ... }:

let
  zfs-helper = pkgs.writeTextFile {
    name = "zfs-helper";
    executable = true;
    destination = "/bin/zfs-helper";
    text = builtins.readFile ./zfs-helper.sh;
  };

  zfs-helper-ssh-prompt = pkgs.writeTextFile {
    name = "zfs-helper-ssh-prompt";
    destination = "/root/.profile";
    text = "zfs-helper onBootPrompt";
  };
in {
  # TODO: Shouldn't be necessary when root is on ZFS
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  # Hibernation on ZFS can cause corruption
  # Plus, this doesn't work with randomly encrypted swap
  boot.kernelParams = [ "nohibernate" ];

  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "Sun, 02:00";

  environment.systemPackages = with pkgs; [
    zfs
    zfs-helper
  ];

  # On safe shutdown, save key to file
  # for reboot
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
      enable = false;
      ssh = {
        enable = true;
        port = 22;

        # Use the RSA key for initrd since ED25519 is used for the host
        hostKeys = [ /etc/ssh/ssh_host_rsa_key ];

        authorizedKeys = [
		  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMXnf0eYbX+aFIdf2ijIeJsVcDwXwgxV4u4e2PjLKll6 david@pavil"
		  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6FKNF/0qdKMmH0D0XMeIix2Kvqh+c5DPGyv+7wpIiqo6snf95oycdcTaTKA6w4ryB0eiuWDlcZTH8+o7QFFPH+4fFN0pB9W/AfAegVRzuRRCxE3J1aw1jX93fVr0x9aa851/4g90IDJvJ7btO9Wp23KzFjrhc7NtrNFZLjNxtuIE+WT9IkRxVWMRwsoSrIIRv2pVRtQnqjxC93UAStZn1PQFoevxOhANkPZ/nQm1kvc2PYTFZSna9GN/sakv4NSjkAosCskwFtiR3iN/H23VsKsJFOo8N6tcapLYul+eTMqW83i6Emov/0yvkE+jcvrIt4jdnbSWbBX4HWnf2n8yyk83t1aRe4pJSvROwolPCvKeOACQiWf5Nk7Ch1hrBbnobs5pTWTGFBZM638ZXhebcVhL8yGciNtQiWIWZ/WIxDCSMklCSGaIl8tWtNzd8ljFJ6Z4RJXcoyC3PwJXGgE8j5RrQ8Plg9wK96kQvF4B5Imo2hpjWouYqPCJ6PozA9es= david@cuttlefish"
		];
      };
    };
  };
}
