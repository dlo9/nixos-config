{ config, pkgs, ... }:

{
  # Use flakes -- see flake.nix for real config
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
