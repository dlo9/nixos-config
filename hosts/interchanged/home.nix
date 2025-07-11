{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:
with lib; {
  imports = [
    "${inputs.self}/home"
  ];

  home.stateVersion = "25.05";

  xdg.configFile."wrap.yaml".source = ./wrap.yaml;

  programs.firefox.enable = true;

  home.packages = with pkgs; [
    kubectl
    flameshot
    notion-app
    slack
    awscli2

    # Use a new launcher since spotlight doesn't find nix GUI applications:
    # https://github.com/nix-community/home-manager/issues/1341
    raycast

    # Golang
    go
    protobuf
    #sqlc

    # Python
    pyenv

    # Shell tools
    gnused
    coreutils-prefixed
    gawk

    # Other tools
    terraform
    gh
    #postman
  ];

  home.sessionVariables = rec {
    # Wipe path to prevent system binaries (e.g., vim) from coming before home-manager ones
    # https://github.com/nix-community/home-manager/issues/3324
    PATH = "";

    # HOMEBREW_CURLRC = "1";
    RUST_BACKTRACE = "1";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    SHELL = "${config.programs.fish.package}/bin/fish"; # Fix for tmux

    GOPRIVATE = "github.com/interxfi,gopkg.interchangefi.com";
    J5_REGISTRY = "https://o5.devcore.zones.interchangefi.com";
    AWS_REGION = "us-west-2";
    IX_CLUSTER = "devcore";
    IX_ENV = "devcore-web";
    AWS_PROFILE = "ixb-devcore";
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "/opt/homebrew/bin"

    # Add nix paths
    "$HOME/.nix-profile/bin"
    "/etc/profiles/per-user/david/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"

    # Re-add system paths (see home.sessionVariables)
    "/usr/local/bin"
    "/System/Cryptexes/App/usr/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  # https://github.com/nix-community/home-manager/issues/5952
  programs.tmux.extraConfig = ''
    set -gu default-command
    set -g default-shell "$SHELL"
  '';

  programs.fish.functions = {
    convert-logs-timestamp = ''
      jq '.ts |= (. | tostring [0:10] | tonumber | localtime | strftime("%Y-%m-%dT%H:%M:%S%z"))' $argv
    '';

    get-random = ''
      while true
        uuidgen | tr -d '\n' | pbcopy
        sleep 0.2
      end
    '';

    unfix = ''
      tr '\001\002' '|?' $argv
    '';
  };

  programs.git.userEmail = "david@interchange.com";

  programs.ssh = {
    enable = true;
  };

  # https://github.com/NixOS/nixpkgs/issues/330735
  programs.vscode = {
    package = mkForce pkgs.vscode;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      bierner.markdown-mermaid
      golang.go
    ];
  };

  home.activation = {
    setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to "${config.wallpapers.default}"'
    '';

    # https://github.com/nix-darwin/nix-darwin/issues/518
    # https://github.com/NUIKit/CGSInternal/blob/master/CGSHotKeys.h
    # https://stackoverflow.com/questions/21878482/what-do-the-parameter-values-in-applesymbolichotkeys-plist-dict-represent
    disableHotkeys = let
      hotkeys = [
        32 # Disable Mission control
        33 # Disable Show application windows
        79 # Move to left space
        81 # Move to right space
      ];

      disableKey = key: "run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${toString key} '<dict><key>enabled</key><false/></dict>'";
      script = lib.concatStringsSep "\n" (map disableKey hotkeys);
    in
      lib.hm.dag.entryBefore ["activateSettings"] script;

    activateSettings = lib.hm.dag.entryAfter ["writeBoundary"] "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u";
  };

  home.file = {
    # Silence "last login" text when a new terminal is opened
    ".hushlogin".text = "";
  };

  launchd.agents = let
    docker-compose = name: {
      enable = true;
      config = {
        KeepAlive = true;
        ProcessType = "Interactive";
        WorkingDirectory = "${config.home.homeDirectory}/Documents/documents/docker-compose/${name}";
        ProgramArguments = ["/usr/local/bin/docker" "compose" "up"];
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/docker-compose/${name}/stderr";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/docker-compose/${name}/stdout";
      };
    };
  in {
    raycast = {
      enable = true;
      config = {
        KeepAlive = true;
        ProcessType = "Interactive";
        Program = "${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/raycast/stderr";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/raycast/stdout";
      };
    };

    autoraise = {
      enable = true;
      config = {
        KeepAlive = true;
        ProcessType = "Interactive";
        ProgramArguments = ["${pkgs.autoraise}/bin/autoraise" "-altTaskSwitcher=true" "-disableKey=control" "-mouseDelta=1" "pollMillis=50" "-delay=10"];
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/autoraise/stderr";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/autoraise/stdout";
      };
    };

    docker-compose = {
      enable = true;
      config = rec {
        KeepAlive = true;
        ProcessType = "Interactive";
        EnvironmentVariables = {
          HOME = config.home.homeDirectory;
          PATH = concatStringsSep ":" config.home.sessionPath;
        };
        WorkingDirectory = "${config.home.homeDirectory}/code/nixos-config/hosts/${hostname}/docker-compose";
        ProgramArguments = ["${WorkingDirectory}/all-docker-compose.sh" "up"];
        StandardErrorPath = "${WorkingDirectory}/logs/all.stderr.log";
        StandardOutPath = "${WorkingDirectory}/logs/all.stdout.log";
      };
    };
  };
}
