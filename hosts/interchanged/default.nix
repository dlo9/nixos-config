{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  user = "david";
in {
  imports = [
    ./remote-build.nix
  ];

  graphical.enable = true;
  developer-tools.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  homebrew = {
    enable = true;

    brews = [
      "ollama"
      "lunchy" # launchctl wrapper: https://github.com/eddiezane/lunchy
    ];

    casks = [
      "docker-desktop"
      "sensiblesidebuttons"
      "launchcontrol"
      "notion"
      "flameshot"
      "caffeine"
      "google-chrome"
      "aerial"

      # Installed here because they expect "helper tools"
      "slack"
      "postman"
    ];
  };

  # Users
  system.primaryUser = "david";
  home-manager.users.${user} = import ./home.nix;

  users.users.${user} = {
    home = "/Users/${user}";
    uid = 501;
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
      #"dl.pstmn.io" = "127.0.0.1"; # Block postman download notifications
      #"desktop-release.notion-static.com" = "127.0.0.1"; # Block notion download notifications
    };
  };

  # Installed the pkgs instead, since this version doesn't have a GUI
  #services.tailscale.enable = true;

  # Better for Tahoe
  services.spacebar.enable = mkForce false;
}
