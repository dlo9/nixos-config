{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
  # lspci -nn | grep -i nvidia
  # sudo virsh net-start default
  gpuIDs = [
    "10de:1b81" # Graphics
    "10de:10f0" # Audio
  ];
in {
  config = {
    boot = {
      # Nvidia GPU passthrough
      # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/5/html/virtualization/chap-virtualization-pci_passthrough
      # https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
      # pci_0000_10_00_0
      kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
        "vfio_virqfd"
      ];

      kernelParams = [
        "iommu=pt"
        ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs)
      ];
    };
  };
}
