{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:
with lib; {
  programs.offlineimap.enable = true;

  systemd.user.services.offlineimap = {
    Unit.Description = "Email backup";
    Install.WantedBy = ["default.target"];
    Service.ExecStart = "${config.programs.offlineimap.package}/bin/offlineimap";
  };

  accounts.email.accounts.fastmail = {
    address = "dlo@fastmail.com";
    realName = "David Orchard";
    userName = "dlo@fastmail.com";
    primary = true;
    flavor = "fastmail.com";

    smtp = {
      host = "smtp.fastmail.com";
      port = 465;
    };

    imap = {
      host = "imap.fastmail.com";
      port = 993;
    };

    passwordCommand = "cat /home/david/.mail/fastmail";

    offlineimap = {
      enable = true;
      extraConfig = {
        account = {
          autorefresh = 60; # Every hour
          synclabels = true; # Only valid for gmail
        };

        local = {
          localfolders = "/slow/backup/david/mail";
          # sync_deletes = "no";
          sep = "/";
        };

        remote = {
          readonly = "True";
        };
      };
    };
  };
}
