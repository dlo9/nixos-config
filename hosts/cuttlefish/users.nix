{ config, pkgs, lib, ... }:

let
  media-id = 568;
in
{
  config = {
    users = {
      groups = {
        media.gid = media-id;
      };

      users = {
        media = {
          uid = media-id;
          group = "media";
          isSystemUser = true;
        };
      };
    };
  };
}
