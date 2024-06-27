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
      ./home-manager.nix
      ./nix.nix
      ./options.nix
      ./secrets.nix
    ]
    ++ (optional isDarwin ./darwin)
    ++ (optional isAndroid ./android)
    ++ (optional isLinux ./nixos);
}
