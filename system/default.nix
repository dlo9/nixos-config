{
  lib,
  pkgs,
  isLinux,
  isDarwin,
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
    ++ (optional isLinux ./nixos);

  # Shells
  programs.fish.enable = true;
  environment.shells = [pkgs.fish];
}
