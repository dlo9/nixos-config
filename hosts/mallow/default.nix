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
      "kafka"
      "pyenv"
      "jenv"

      "unixodbc"
      "msodbcsql18"
    ];

    casks = [
      "docker"
      "firefox"
      "google-drive"
      "jdk-mission-control"
      "nosqlbooster-for-mongodb"
      "sensiblesidebuttons"

      # Team fun
      "steam"
    ];
  };

  # Users
  home-manager.users.${user} = import ./home.nix;

  users.users.${user} = {
    home = "/Users/${user}";
    uid = 503;
    gid = 20;
    shell = pkgs.fish;
  };

  # Launch raycast on start
  environment.userLaunchAgents."raycast.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>EnvironmentVariables</key>
      <dict>
        <key>PATH</key>
        <string>$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin</string>
      </dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>raycast</string>
      <key>ProcessType</key>
      <string>Interactive</string>
      <key>ProgramArguments</key>
      <array>
        <string>${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast</string>
      </array>
    </dict>
    </plist>
  '';
}
