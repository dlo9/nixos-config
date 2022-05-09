# Search for config options at: https://search.nixos.org/options?channel=21.11
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
