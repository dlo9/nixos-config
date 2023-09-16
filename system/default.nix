{
  lib,
  pkgs,
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
    ++ (optional pkgs.stdenv.isDarwin ./darwin)
    ++ (optional pkgs.stdenv.isLinux ./nixos);

  # Shells
  programs.fish.enable = true;
  environment.shells = [pkgs.fish];
}
