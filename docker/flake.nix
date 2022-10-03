{
  inputs = {
    #nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05-small;
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    # FUTURE: set to a specific release, or else changes can become out of sync with nixos
    #home-manager.url = github:nix-community/home-manager/release-22.05;
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # nix build 'path:.#packages.x86_64-linux.vm'
  # QEMU_OPTS="-vga qxl" QEMU_NET_OPTS=hostfwd=tcp::60022-:22,hostfwd=tcp::5900-:5900,hostfwd=tcp::8080-:8080 ./result/bin/run-nixos-vm
  outputs = { self, nixpkgs, nixos-generators, ... }@inputs:
    let
      configuration =
        ({ config, pkgs, lib, ... }: {
          system.stateVersion = "22.11";

          # Steam requires unfree
          nixpkgs.config.allowUnfree = true;

          # Audio
          nixpkgs.config.pulseaudio = true;

          # Video
          hardware.opengl = {
            enable = true;
            driSupport = true;
            driSupport32Bit = true;
          };

          # Window manager
          #services.xserver = {
          #  enable = true;
          #  desktopManager = {
          #    #xterm.enable = false;
          #    #lxqt.enable = true;
          #  };
          #  windowManager.icewm.enable = true;
          #  #displayManager.defaultSession = "icewm";
          #};

          # Steam
          programs.steam = {
            enable = true;
            remotePlay.openFirewall = true;
          };

          # Flatpak (for sunshine/moonlight)
          services.flatpak.enable = true;
          xdg.portal.enable = true;
          xdg.portal.wlr.enable = true;

          # Expose VNC and VNC-HTTP ports
          networking.firewall.allowedTCPPorts = [
            5900
            8080
          ];

          # Window manager
          programs.xwayland.enable = true;
          # programs.sway = {
          #   enable = true;
          #   wrapperFeatures = {
          #     base = true;
          #     gtk = true;
          #   };

          #   extraSessionCommands = ''
          #     # SDL:
          #     export SDL_VIDEODRIVER=wayland
          #     # QT (needs qt5.qtwayland in systemPackages):
          #     export QT_QPA_PLATFORM=wayland-egl
          #     export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
          #     # Fix for some Java AWT applications (e.g. Android Studio),
          #     # use this if they aren't displayed properly:
          #     export _JAVA_AWT_WM_NONREPARENTING=1
          #   '';
          # };

          # Other packages
          environment.noXlibs = false; # Without this, X11 packages are built and fail
          environment.systemPackages = with pkgs; [
            # X11
            #x11vnc

            # Wayland
            #labwc
            wayvnc

            # Browser-based VNC
            novnc
            python310Packages.websockify

            # Extra steam packages
            cairo
            #cmake
            #egl-wayland

            # Start vnc with: x11vnc -display :0
            (pkgs.writeScriptBin "novnc-server" ''
              #!/bin/sh

              echo "Starting VNC Server"
              #x11vnc -display :0 &
              wayvnc &

              echo "Starting VNC Client"
              novnc --web ${pkgs.novnc}/share/webapps/novnc --listen 8080 --vnc localhost:5900
            '')
          ];

          # Users
          users.mutableUsers = false;
          users.users = {
            root.hashedPassword = "$6$0/6kZLj/YlKMK7c5$eW4UjS1OE6OtEt9DI6JoeUkc8xi3eLDE2xc4/nD50L8NPYU7m5QpCxPVAYLF2t.hw76Z5/LR7uJztN8fjDVqq.";

            steam = {
              isNormalUser = true;
              uid = 1000;
              shell = pkgs.fish;
              password = "steam"; # Don't care that this is plaintext
              createHome = true;
              extraGroups = [
                "audio"
                "video"
              ];
            };
          };

          # Autologin
          services.getty.autologinUser = "steam";

          environment.shellInit = ''
            #if [ -z $DISPLAY ]; then
              WLR_BACKENDS=headless WAYLAND_DISPLAY=HEADLESS-1 sway
            #fi
          '';

          # systemd.services.sway = {
          #   wantedBy = [ "multi-user.target" ];

          #   serviceConfig = {
          #     User = "steam";
          #   };

          #   script = ''
          #     #!/bin/sh

          #     . /etc/pam/environment
          #     . /etc/profile

          #     sway
          #     #${config.home-manager.users.steam.wayland.windowManager.sway.package}/bin/sway
          #   '';
          # };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "home-manager-backup";
            users.steam = {
              home.stateVersion = "22.11";

              # systemd.user.services = {
              #   sway = {
              #     Service = {
              #       Type = "oneshot";
              #       ExecStart = "${pkgs.sway}/bin/sway";
              #     };

              #     Install = {
              #       WantedBy = [ "default.target" ];
              #     };
              #   };
              # };

              wayland.windowManager.sway = {
                enable = true;

                config = {
                  modifier = "Mod4"; # Windows key

                  output = {
                    HEADLESS-1 = { mode = "1920x1080@60Hz"; position = "0,0"; };
                  };
                };

                #include ${config.home-manager.users.steam.wayland.windowManager.sway.package}/etc/sway/config
                extraConfig = ''
                  exec novnc-server > /tmp/startall.log
                '';
              };
            };
          };
        });
    in
    {
      packages.x86_64-linux = {
        vm = nixos-generators.nixosGenerate {
          format = "vm";
          system = "x86_64-linux";

          modules = [
            inputs.home-manager.nixosModules.home-manager
            configuration
          ];
        };

        docker = nixos-generators.nixosGenerate {
          format = "docker";
          system = "x86_64-linux";

          modules = [
            inputs.home-manager.nixosModules.home-manager
            configuration
          ];
        };
      };
    };
}
