{ pkgs, pkgs-unstable }:

with pkgs.dockerTools;

let
  profile = pkgs.writeText "profile" ''
    export PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/sbin:/bin:/usr/sbin:/usr/bin
    export MANPATH=$HOME/.nix-profile/share/man:/nix/var/nix/profiles/default/share/man:/usr/share/man

    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    export XDG_RUNTIME_DIR=/run/user/1000
  '';

  sway-config = pkgs.writeText "sway-config" ''
    include /etc/sway/config

    output "HEADLESS-1" {
      # mode 1920x1080@60Hz
      position 0,0
    }

    exec novnc-server
  '';
in
# nix-build steam.nix && docker load < result && docker run -it -p 8080:8080 -p 5900:5900 steam:latest
  # nix-build steam.nix && docker load < result && docker compose run --service-ports steam
  # http://localhost:8080/vnc.html?host=localhost&port=8080
buildImage {
  name = "steam";
  tag = "latest";

  #fromImage = "nixos";
  #fromImageName = "nixos/nix";
  #fromImageTag = "latest";

  config = {
    #Cmd = [ "steam" ];
    Cmd = [ "${pkgs.fish}/bin/fish" ];

    Env = [
      "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      "XDG_RUNTIME_DIR=/run/user/1000"

      # For running sway headless
      "WLR_BACKENDS=headless"
      "WAYLAND_DISPLAY=HEADLESS-1"
    ];

    User = "steam";
    WorkDir = "/home/steam";
  };

  runAsRoot = ''
    #!${pkgs.runtimeShell}
    ${pkgs.dockerTools.shadowSetup}

    groupadd -g 100 users
    groupadd -g 17 audio
    groupadd -g 26 video

    useradd -m -u 1000 -g users -G audio,video steam

    mkdir -p /home/steam/.config/sway
    cp "${sway-config}" /home/steam/.config/sway/config

    chown -R steam:users /home/steam

    mkdir -p /run/user/1000
    chown -R steam:users /run/user/1000
  '';

  #copyToRoot = pkgs.buildEnv {
  contents = pkgs.buildEnv {
    name = "root";

    pathsToLink = [ "/share/man" "/share/doc" "/bin" "/etc" ];
    extraOutputsToInstall = [ "man" "doc" ];

    paths = with pkgs; with pkgs.dockerTools; [
      (runCommand "profile" { } ''
        mkdir -p $out/etc/profile.d
        cp ${profile} $out/etc/profile.d/profile.sh
      '')

      sway
      foot # Terminal emulator
      xwayland
      xorg.xev

      #mesa
      #mesa-demos

      steam

      novnc
      python310Packages.websockify

      (pkgs.writeScriptBin "novnc-server" ''
        #!/bin/sh

        echo "Starting VNC Server"
        #x11vnc -display :0 &
        wayvnc &

        echo "Starting VNC Client"
        novnc --web ${pkgs.novnc}/share/webapps/novnc --listen 8080 --vnc localhost:5900
      '')

      wayvnc

      # Misc
      dbus

      # Nix base image
      # https://nixos.org/manual/nix/unstable/installation/installing-docker.html#what-is-included-in-nixs-docker-image
      nix
      bashInteractive
      coreutils-full
      gnutar
      gzip
      gnugrep
      which
      curl
      less
      wget
      man
      cacert.out
      findutils


      # Debugging
      coreutils-full
      vim
      su
      ps

      # DockerTools helpers:
      # https://ryantm.github.io/nixpkgs/builders/images/dockertools/#ssec-pkgs-dockerTools-helpers
      usrBinEnv
      binSh
      #caCertificates
      #fakeNss
    ];
  };
}

# pkgs.dockerTools.buildImage {
#   name = "hello-docker";
#   config = {
#     Cmd = [ "${pkgs.hello}/bin/hello" ];
#   };
# }
