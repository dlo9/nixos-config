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
  #boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;

  # Need older ZFS because of older kernel
  boot.zfs.package = pkgs.zfs;

  # Test with:
  # nix run nixpkgs#clinfo
  # nix shell nixpkgs#libva-utils -c vainfo
  # nix shell nixpkgs#vulkan-tools -c vulkaninfo
  hardware.graphics.extraPackages = with pkgs; [
    intel-compute-runtime
    vpl-gpu-rt
    intel-media-driver
    #intel-vaapi-driver
  ];

  # Conflicts with TLP, not sure where it's enabled
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;

    # https://linrunner.de/tlp/settings/index.html
    settings = {
      WIFI_PWR_ON_AC = "on";
      RADEON_DPM_STATE_ON_AC = "battery"; # Probably doesn't matter
      PLATFORM_PROFILE_ON_AC = "low-power";
      DEVICES_TO_DISABLE_ON_STARTUP = "wifi";
      DEVICES_TO_ENABLE_ON_STARTUP = "bluetooth";
      RUNTIME_PM_ON_AC = "auto";
    };
  };
}
