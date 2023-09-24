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

    users = {
      groups = {
        media.gid = media-id;
      };

      users = {
        chelsea = {
          uid = 1001;
          group = "users";
          isSystemUser = true;
          createHome = false;
        };

        media = {
          uid = media-id;
          group = "media";
          isSystemUser = true;
        };
      };
    };
  };
}
