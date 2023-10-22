{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    home-manager.users.david = import ./home.nix;

    users = {
      groups.samba = {};

      users = {
        david = {
          extraGroups = ["samba"];
        };

        michael = {
          uid = 1001;
          isNormalUser = true;
          hashedPassword = "$6$S/H.nEE7XEPdyO6v$ENulPNgv2WGmwdCD7zluMNasQ/wPFdc61wjxC2/aFXcl9dLvbMzzeSeVI9V5dxycJaojJRFUtqKYNPJIX767P1";
          createHome = false;
          extraGroups = ["samba"];
        };

        sue = {
          uid = 1002;
          isNormalUser = true;
          createHome = false;
          extraGroups = ["samba"];
        };
      };
    };
  };
}
