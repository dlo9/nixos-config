{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  user = "dorchard";
in {
  graphical.enable = true;
  developer-tools.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  security.pki.certificateFiles = [
    ./ca-certificates.crt
  ];

  homebrew = {
    enable = true;

    # Workaround for EULA
    # https://github.com/microsoft/homebrew-mssql-release/issues/86
    extraConfig = ''
      module Utils
        ENV['HOMEBREW_ACCEPT_EULA']='y'
      end

      brew "mssql-tools18"
    '';

    taps = [
      {
        name = "microsoft/mssql-release";
        clone_target = "https://github.com/Microsoft/homebrew-mssql-release";
        force_auto_update = true;
      }
    ];

    brews = [
      "jenv"
      "msodbcsql18"
      "unixodbc"
      "ollama"
    ];

    casks = [
      "docker"
      "firefox"
      "flameshot"
      "intellij-idea"
      "kreya"
      "logseq"
      "nosqlbooster-for-mongodb"
      "onedrive"
      "sensiblesidebuttons"
      "steam"
      "microsoft-teams"

      # Gui for launchctl
      "launchcontrol"
    ];
  };

  # Users
  system.primaryUser = "dorchard";
  home-manager.users.${user} = import ./home.nix;

  users.users.${user} = {
    home = "/Users/${user}";
    uid = 503;
    gid = 20;
    shell = pkgs.fish;
  };

  # Check current DNS settings with: scutil --dns
  # This also adds domains as a resolver in /etc/resolver. See:
  # - https://github.com/suth/mac-traefik-config
  # - https://vninja.net/2020/02/06/macos-custom-dns-resolvers
  services.dnsmasq = {
    enable = true;

    addresses = {
      "laptop" = "127.0.0.1";
    };
  };
}
