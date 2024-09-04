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
          hashedPassword = "$6$CiWKN4ueep82fXQG$Vhk6usx2xJ.OkcrTaXVnHXOlPhGPosDYBFvR3LECpRMFI5PS6/d6nMkz2mc2Tc3aIK68TnoLnT98BJcHVS.o71";
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
