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
    common-gpu-nvidia-nonprime
    common-hidpi

    ./quirks.nix
    ./generated.nix
  ];

  #sys.graphical.nvidia = true;
  boot.blacklistedKernelModules = ["nouveau"];
  hardware.nvidia = {
    #modesetting.enable = true;
    powerManagement.enable = true;
    #open = false;
    #nvidiaSettings = true;
    #package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cutensor
    cudaPackages.cudnn
    nvidia-vaapi-driver

    # Contains "new" flags for Nvidia GPUs which are in all the docs
    #(ffmpeg_5-full.override {
    #  nv-codec-headers = nv-codec-headers-11;
    #})
  ];
}
