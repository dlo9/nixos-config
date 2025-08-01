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
    ./eww
    ./hyprland.nix
    ./waybar
    ./web.nix
  ];

  config = mkIf config.graphical.enable {
    home.pointerCursor = {
      enable = isLinux;
      name = "Numix-Cursor-Light";
      package = pkgs.numix-cursor-theme;
      gtk.enable = true;
      x11.enable = true;
    };

    programs = {
      # Terminal
      alacritty = {
        enable = true;

        # https://alacritty.org/config-alacritty.html
        settings = {
          terminal.shell = {
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

          # Map Win to Alt for zelliJ: https://github.com/zellij-org/zellij/issues/2318
          # Use `showkey -a` to get the unicode for alt
          # https://github.com/zellij-org/zellij/blob/f6ec1a13853d25df3412ad9f759ea857719bb2aa/zellij-utils/assets/config/default.kdl#L150
          keyboard.bindings =
            (map (key: {
              inherit key;
              mods = "Super";
              chars = ''\u001b${key}'';
            }) (stringToCharacters "niohljk-=[]"))
            ++ [
              {
                key = "=";
                mods = "Control";
                action = "IncreaseFontSize";
              }
              {
                key = "-";
                mods = "Control";
                action = "DecreaseFontSize";
              }
              {
                key = "0";
                mods = "Control";
                action = "ResetFontSize";
              }
            ];
        };
      };

      # Other
      vim.plugins = with pkgs.vimPlugins; [
        # Fix copy to system clipboard on wayland
        vim-wayland-clipboard
      ];

      zathura.enable = mkDefault isLinux;
    };

    xdg = {
      enable = mkDefault true;

      # Default applications
      mimeApps = {
        enable = mkDefault isLinux;

        # See desktop files with:
        # ls /etc/profiles/per-user/david/share/applications /run/current-system/sw/share/applications
        defaultApplications = {
          "image/jpeg" = "pix.desktop";
          "image/gif" = "pix.desktop";
          "image/png" = "pix.desktop";
          "image/svg+xml" = "pix.desktop";
          "image/tiff" = "pix.desktop";
          "image/webp" = "pix.desktop";
          "application/pdf" = "org.pwmt.zathura.desktop";
          "text/markdown" = "code.desktop";
          "text/xml" = "code.desktop";
          "text/csv" = "code.desktop";
          "text/plain" = "code.desktop";
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
          nemo
          #peazip # Broke with 24.05 upgrade

          # USB installer
          ventoy-bin

          # Display tool
          ddcutil

          #kopia # Backups

          #geekbench_6

          # Scanning
          simple-scan

          # Networking utils
          wpa_supplicant_gui

          # HDD info
          smartmontools

          # Notes app
          #anytype
          #master.appflowy

          # Video player
          mpv

          # PDF viewers
          kdePackages.okular

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

          #zoom-us
          whatsapp-for-linux

          # Image viewer
          #loupe
          pix

          libreoffice
          cameractrls-gtk4
        ])

        [
          # Fonts
          nerd-fonts.noto
          noto-fonts-emoji

          b612
          open-sans

          # Required for gtk: https://github.com/nix-community/home-manager/issues/3113
          #dconf

          # So that links open in a browser when clicked from other applications
          # (e.g. vscode)
          xdg-utils

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
      flameshot = {
        enable = mkDefault isLinux;
        package = pkgs.unstable.flameshot.override {
          enableWlrSupport = true;
        };
      };
    };

    # Restart systemd services that have changed
    systemd.user.startServices = "sd-switch";
  };
}
