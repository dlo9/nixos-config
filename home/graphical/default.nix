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
        settings =
          {
            window.opacity = 0.9;
            decorations = "full";
            font = {
              normal.family = mkDefault config.font.family;
              size = mkDefault config.font.size;
            };

            save_to_clipboard = true;
            cursor.style = {
              shape = "Block";
              blinking = "Always";
              shell = {
                program = config.programs.fish.package;
                args = ["--login"];
              };
            };

            mouse.hide_when_typing = false;
          }
          // (pkgs.dlo9.lib.fromYAML (config.scheme inputs.base16-alacritty));
      };

      # Other
      vim.plugins = with pkgs.vimPlugins; [
        # Fix copy to system clipboard on wayland
        vim-wayland-clipboard
      ];
    };

    xdg = {
      enable = mkDefault true;

      # Default applications
      mimeApps = {
        enable = mkDefault isLinux;

        # See desktop files in /run/current-system/sw/share/applications
        defaultApplications = {
          "application/pdf" = "org.pwmt.zathura.desktop";
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

      theme = {
        #package = pkgs.vimix-gtk-themes;

        name = "FlatColor-base16";
        package = let
          gtk2-theme = config.scheme {
            templateRepo = inputs.base16-gtk;
            target = "gtk-2";
          };

          gtk3-theme = config.scheme {
            templateRepo = inputs.base16-gtk;
            target = "gtk-3";
          };
        in
          pkgs.dlo9.flatcolor-gtk-theme.overrideAttrs (oldAttrs: {
            # Build instructions: https://github.com/tinted-theming/base16-gtk-flatcolor
            # This builds, but doesn't seem to work very well?
            postInstall = ''
              # Base theme info
              base_theme=FlatColor
              base_theme_path="$out/share/themes/$base_theme"

              new_theme="$base_theme-base16"
              new_theme_path="$out/share/themes/$new_theme"

              # Clone and rename theme
              cp -r "$base_theme_path" "$new_theme_path"
              grep -Rl "$base_theme" "$new_theme_path" | xargs -n1 sed -i "s/$base_theme/$new_theme/"

              # Rewrite colors into theme files
              # This is specific to FlatColor, since gtk themes dont standarize base color variables
              printf "%s\n" 'include "${gtk2-theme}"' "$(sed -E '/.*#[a-fA-F0-9]{6}.*/d' "$base_theme_path/gtk-2.0/gtkrc")" > "$new_theme_path/gtk-2.0/gtkrc"
              printf "%s\n" '@import url("${gtk3-theme}");' "$(sed '1,10d' "$base_theme_path/gtk-3.0/gtk.css")" > "$new_theme_path/gtk-3.0/gtk.css"
              printf "%s\n" '@import url("${gtk3-theme}");' "$(sed '1,26d' "$base_theme_path/gtk-3.20/gtk.css")" > "$new_theme_path/gtk-3.20/gtk.css"
            '';
          });
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

          # USB installer
          ventoy-bin

          # Display tool
          ddcutil

          #kopia # Backups

          # Signal
          signal-desktop

          #geekbench5

          # Scanning
          gnome.simple-scan

          # Networking utils
          wpa_supplicant_gui

          # HDD info
          smartmontools

          # Notes app
          unstable.anytype

          # Video player
          mpv

          # PDF viewers
          okular
          zathura

          # Key tester
          wev

          # Partitioning
          gparted

          # Monitor control
          ddcui

          # USB flasher
          popsicle

          # GUI-ish bluetooth control
          bluetuith
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

          # Required for gtk: https://github.com/nix-community/home-manager/issues/3113
          dconf

          # So that links open in a browser when clicked from other applications
          # (e.g. vscode)
          xdg-utils

          # Notes app
          obsidian

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

      # File syncing
      syncthing.enable = mkDefault isLinux;

      # Screenshots
      flameshot.enable = mkDefault isLinux;
    };

    # Restart systemd services that have changed
    systemd.user.startServices = "sd-switch";
  };
}
