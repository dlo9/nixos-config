# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "mpt3sas" "isci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "fast/nixos/root";
      fsType = "zfs";
    };

  fileSystems."/root" =
    { device = "fast/home/root";
      fsType = "zfs";
    };

  fileSystems."/var/lib/containerd/io.containerd.snapshotter.v1.zfs" =
    { device = "fast/containerd";
      fsType = "zfs";
    };

  fileSystems."/home/david" =
    { device = "fast/home/david";
      fsType = "zfs";
    };

  fileSystems."/boot/efi0" =
    { device = "/dev/disk/by-uuid/D10A-E7FF";
      fsType = "vfat";
    };

  fileSystems."/boot/efi1" =
    { device = "/dev/disk/by-uuid/D007-7D72";
      fsType = "vfat";
    };

  fileSystems."/boot/efi2" =
    { device = "/dev/disk/by-uuid/388C-755D";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/cfabdcdc-e671-43ee-83d9-c487e5376454"; }
      { device = "/dev/disk/by-uuid/2bab50cb-c97d-4e2f-8ffc-0d957b1e7cbf"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.docker0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0f0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0f1.useDHCP = lib.mkDefault true;
  # networking.interfaces.flannel.1.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}