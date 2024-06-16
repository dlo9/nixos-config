{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  ...
}:
with lib; {
  imports = [
    ./developer-tools.nix
    ./hyprland.nix
    ./sway.nix
    ./waybar
    ./web.nix
  ];

  config = mkIf config.graphical.enable {
    home.pointerCursor =
      if isLinux
      then {
        name = "Numix-Cursor-Light";
        package = pkgs.numix-cursor-theme;
        gtk.enable = true;
        x11.enable = true;
      }
      else null;

    programs = {
      # Image viewer
      feh.enable = mkDefault isLinux;

      # Terminal
      alacritty = {
        enable = true;

        # https://github.com/alacritty/alacritty/blob/master/alacritty.yml
        settings = {
          shell = {
            program = "${config.programs.fish.package}/bin/fish";
            args = ["--login"];
          };

          window = {
            opacity = 0.9;
            dynamic_padding = true;
            padding = {
              x = 5;
              y = 5;
            };
          };

          font = {
            normal.family = mkDefault config.font.family;
            size = mkDefault config.font.size;
          };

          selection.save_to_clipboard = true;
          cursor.style = {
            shape = "Block";
            blinking = "Always";
          };

          mouse.hide_when_typing = false;
        };
      };

      # Other
      vim.plugins = with pkgs.vimPlugins; [
        # Fix copy to system clipboard on wayland
        vim-wayland-clipboard
      ];

      zathura.enable = true;
    };

    xdg = {
      enable = mkDefault true;

      desktopEntries = with pkgs;
        optionalAttrs isLinux {
          qimgv = {
            name = "qimgv";
            exec = "qimgv -- %F";
            mimeType = [
              "image/jpeg"
            ];
          };
        };

      # Default applications
      mimeApps = {
        enable = mkDefault isLinux;

        # See desktop files in /run/current-system/sw/share/applications
        defaultApplications = {
          "image/jpeg" = "qimgv.desktop";
        };
      };
    };

    gtk = {
      enable = mkDefault isLinux;

      iconTheme = {
        #package = pkgs.vimix-icon-theme;
        #name = "Vimix";

        name = "Flat-Remix-Teal-Dark";
        package = pkgs.flat-remix-icon-theme;
      };
    };

    home.packages = with pkgs;
      flatten [
        (optionals isLinux [
          # Clipboard helper
          wl-clipboard

          # For debugging themes
          pkgs.dlo9.lxappearance-xwayland

          # File manager
          cinnamon.nemo
          #peazip # Broke with 24.05 upgrade

          # USB installer
          ventoy-bin

          # Display tool
          ddcutil

          #kopia # Backups

          # Signal
          signal-desktop

          geekbench_6

          # Scanning
          gnome.simple-scan

          # Networking utils
          wpa_supplicant_gui

          # HDD info
          smartmontools

          # Notes app
          anytype
          master.appflowy

          # Video player
          mpv

          # PDF viewers
          okular

          # Key tester
          wev

          # Partitioning
          gparted

          # Monitor control
          ddcui

          # USB flasher
          # popsicle

          # GUI-ish bluetooth control
          bluetuith

          zoom-us

          # Image viewer
          qimgv

          # Music
          spotify

          # VNC
          # Normal package is missing H.264 encoding
          pkgs.dlo9.tigervnc

          # Password manager
          bitwarden

          libreoffice
        ])

        [
          # Fonts
          # Nerdfonts is huge, so only install specific fonts
          # https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/data/fonts/nerdfonts/shas.nix
          (nerdfonts.override {
            fonts = [
              "Noto"
            ];
          })

          noto-fonts-emoji

          b612
          open-sans

          # Required for gtk: https://github.com/nix-community/home-manager/issues/3113
          dconf

          # So that links open in a browser when clicked from other applications
          # (e.g. vscode)
          xdg-utils

          # Notes app
          #obsidian

          # Networking utils (telnet)
          inetutils
        ]
      ];

    services = {
      # Bluetooth controls
      blueman-applet.enable = mkDefault isLinux;

      # Enable red-shifted nightime display
      gammastep = {
        enable = mkDefault isLinux;
        provider = "geoclue2";
        tray = true;
      };

      # Screenshots
      flameshot.enable = mkDefault isLinux;
    };

    # Restart systemd services that have changed
    systemd.user.startServices = "sd-switch";
  };
}
