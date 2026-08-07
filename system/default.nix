{
  lib,
  pkgs,
  isLinux,
  isDarwin,
  isAndroid,
  hostname,
  ...
}:
with lib; {
  imports =
    [
      ./features.nix
      ./home-manager.nix
      ./nix.nix
      ./secrets.nix
      ./theme.nix
    ]
    ++ (optional isDarwin ./darwin)
    ++ (optional isAndroid ./android)
    ++ (optional isLinux ./nixos);
}
