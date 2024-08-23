{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd-pstate
    common-cpu-amd
    common-gpu-intel
    common-hidpi

    #./nvidia.nix
    ./quirks.nix
    ./generated.nix
  ];

  # Need older kernel because openvino is broken on 6.8
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;

  # Need older ZFS because of older kernel
  boot.zfs.package = pkgs.zfs;

  # Test with:
  # nix run nixpkgs#clinfo
  # nix shell nixpkgs#libva-utils -c vainfo
  # nix shell nixpkgs#vulkan-tools -c vulkaninfo
  hardware.opengl.extraPackages = with pkgs; [
    intel-compute-runtime
    onevpl-intel-gpu # Replaced by vpl-gpu-rt soon
    intel-media-driver
    intel-vaapi-driver
  ];
}
