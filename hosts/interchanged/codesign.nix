# Host-specific: which packages and app bundles get re-signed with the stable
# codesign cert (for persistent TCC grants). The mechanism is generic — see
# lib/codesign.nix (signPackage/mkSignScript) and home/codesign.nix (activation).
{
  config,
  pkgs,
  lib,
  mylib,
  ...
}: let
  user = config.system.primaryUser;
  home = "/Users/${user}";
in {
  # Point the launchd agents at the signed wrappers.
  services.yabai.package = lib.mkForce (mylib.codesign.signPackage {
    package = pkgs.yabai;
    identifier = "com.koekeishiya.yabai";
    inherit home;
  });

  services.skhd.package = lib.mkForce (mylib.codesign.signPackage {
    package = pkgs.skhd;
    identifier = "com.koekeishiya.skhd";
    inherit home;
  });

  # Drive the activation signer (runs as the user).
  home-manager.users.${user}.codesign = {
    packages = [
      config.services.yabai.package
      config.services.skhd.package
    ];
    bundles = ["${home}/Applications/Home Manager Apps/Alacritty.app"];
  };
}
