# Thanks to these nix configs for examples:
# https://github.com/JayRovacsek/nix-config/blob/7bcf9aeb5f5b692a470f55678a1d62bcdba57d0f/modules/nvidia/nvenc-unlock.nix
# https://github.com/babbaj/nix-config

{ config
, lib
, driverPackage ? config.boot.kernelPackages.nvidiaPackages.stable
, patchNvenc ? false
, patchNvfbc ? false
}:

let
  nvenc = import ./nvenc.nix;
  nvfbc = import ./nvfbc.nix;
in
driverPackage.overrideAttrs ({ version, preFixup ? "", ... }: {
  preFixup = lib.intersperse "\n" [
    preFixup

    (
      let patch = nvenc."${version}"; in
      lib.optionalString patchNvenc ''
        sed -i '${patch.patch}' $out/lib/${patch.file}.${version}
      ''
    )

    (
      let patch = nvfbc."${version}"; in
      lib.optionalString patchNvfbc ''
        sed -i '${patch.patch}' $out/lib/${patch.file}.${version}
      ''
    )
  ];
})
