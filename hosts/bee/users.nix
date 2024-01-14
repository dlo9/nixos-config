{
  config,
  pkgs,
  lib,
  ...
}: let
  media-id = 568;
in {
  config = {
    home-manager.users.david = import ./home.nix;
  };
}
