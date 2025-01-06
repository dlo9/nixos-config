{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko = {
    enableConfig = true;
    devices = {
      disk.fast = {
        #imageSize = "20G";
        type = "disk";
        device = "/dev/disk/by-id/mmc-LX128_0x41e90373";

        content = {
          type = "gpt";
          partitions = {
            # mbr = {
            #   size = "1M";
            #   type = "EF02";
            # };

            EFI = {
              size = "1G";
              type = "EF00";
              name = "EFI";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/EFI";
              };
            };

            swap = {
              size = "1G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };

            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
