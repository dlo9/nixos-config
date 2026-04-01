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
        samba = {};
      };

      users = {
        david.extraGroups = [
          "media"
          "samba"
        ];

        chelsea = {
          uid = 1001;
          group = "users";
          isSystemUser = true;
          hashedPassword = "$6$CiWKN4ueep82fXQG$Vhk6usx2xJ.OkcrTaXVnHXOlPhGPosDYBFvR3LECpRMFI5PS6/d6nMkz2mc2Tc3aIK68TnoLnT98BJcHVS.o71";
          createHome = false;
          extraGroups = ["samba"];
        };

        adam = {
          uid = 1002;
          group = "users";
          isSystemUser = true;
          hashedPassword = "$6$6.kE5Auur2t0zL6q$GkuAYw80sGVvIFDMAKlCxYwyzTSRqIoA1Ely5DKGy7G5Rt3PJHQBRocmZFv4PhJzsOMix0nm840G71DE1SqJd/";
          createHome = false;
          extraGroups = ["samba"];
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
