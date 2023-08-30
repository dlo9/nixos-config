{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  wallpaper = pkgs.fetchurl {
    name = "spaceman";
    url = https://forum.endeavouros.com/uploads/default/original/3X/c/d/cdb27eeb063270f9529fae6e87e16fa350bed357.jpeg;
    sha256 = "02b892xxwyzzl2xyracnjhhvxvyya4qkwpaq7skn7blg51n56yz2";
  };
in {
  xdg.configFile."wrap.yaml" = {
    text = mkForce null;
    source = ./wrap.yaml;
  };

  home.packages = with pkgs; [
    kubectl

    # gcloud components install gke-gcloud-auth-plugin
    (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
    ]))

    rnix-lsp # Nix language server

    # Use a new launcher since spotlight doesn't find nix GUI applications:
    # https://github.com/nix-community/home-manager/issues/1341
    raycast

    # Fonts
    # Nerdfonts is huge, so only install specific fonts
    # https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/data/fonts/nerdfonts/shas.nix
    (nerdfonts.override {
      fonts = [
        "Noto"
      ];
    })

    noto-fonts-emoji

    # Java tools
    visualvm
    jetbrains.idea-ultimate
    gradle
    groovy
    google-java-format
    maven

    # Golang
    go
    protobuf

    # Kafka
    kcat
    kafkactl

    # Python
    # python38
    # python39
    # python310Full
    # python311
    # python312

    # Shell tools
    gnused
    coreutils-prefixed
    gawk

    # Bazel
    bazelisk
    bazel-buildtools

    # Other tools
    ansible
    # nodejs
    mongosh
    openldap
    terraform
    rustup

    # SQL Server
    # unixODBC
    # unixODBCDrivers.msodbcsql17

    # Window manager/hotkeys
    skhd

    # Business apps
    slack
    zoom-us
  ];

  home.sessionVariables = {
    # Java versions
    JAVA_HOME = "${pkgs.jdk}/lib/openjdk";
    JAVA_8_HOME = "${pkgs.jdk8}/lib/openjdk";
    JAVA_11_HOME = "${pkgs.jdk11}/lib/openjdk";
  };

  programs.ssh = {
    enable = true;
    matchBlocks."d1lrtcappprd?".extraOptions = {
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };

  home.activation = {
    setWallpaper = ''
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${wallpaper}"'
    '';
  };
}
