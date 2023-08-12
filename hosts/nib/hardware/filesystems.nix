{ diskId }:

let
  diskById = "/dev/disk/by-id/${diskId}";
  adminUser = "david";
in
{
  config = {
    # This will be duplicated once a hardware file is generated
    fileSystems."/" = {
      device = "fast/nixos/root";
      fsType = "zfs";
    };

    fileSystems."/home/david" = {
      device = "fast/home/david";
      fsType = "zfs";
    };

    fileSystems."/root" = {
      device = "fast/home/root";
      fsType = "zfs";
    };

    fileSystems."/boot" = {
      device = "${diskById}-part1";
      fsType = "vfat";
    };

    swapDevices = [
      { device = "${diskById}-part2"; }
    ];
  };
}
