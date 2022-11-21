{ config, pkgs, lib, inputs, sysCfg, ... }:

with lib;
with types;
with builtins;

let
  cfg = config.home.gui;
in
{
  imports = [
    ./sway
  ];

  options.home.gui = {
    enable = mkEnableOption "user graphical programs" // { default = sysCfg.graphical.enable; };
    bluetooth.enable = mkEnableOption "bluetooth applet" // { default = true; };
  };

  config = mkIf cfg.enable {
    home.pointerCursor = {
      name = "Numix-Cursor-Light";
      package = pkgs.numix-cursor-theme;
    };

    programs = {
      qutebrowser.enable = true;

      vim.plugins = with pkgs.vimPlugins // sysCfg.pkgs.vimPlugins; [
        # Fix copy to system clipboard on wayland
        vim-wayland-clipboard
      ];

      alacritty = {
        enable = true;

        # https://github.com/alacritty/alacritty/blob/master/alacritty.yml
        settings = {
          window.opacity = 0.9;
          decorations = "full";
          font = {
            normal.family = "NotoSansMono Nerd Font";
            #size = 11;
          };

          save_to_clipboard = true;
          cursor.style = {
            shape = "Block";
            blinking = "Always";
            shell = {
              program = config.programs.fish.package;
              args = [ "--login" ];
            };
          };

          mouse.hide_when_typing = false;
        } // (sysCfg.lib.fromYAML (config.scheme inputs.base16-alacritty));
      };

      vscode = {
        enable = true;

        # Necessary for extensions for now
        # https://github.com/nix-community/home-manager/issues/2798
        mutableExtensionsDir = true;

        extensions = with pkgs.vscode-extensions // sysCfg.pkgs.vscode-extensions; [
          shan.code-settings-sync
          jnoortheen.nix-ide
        ];
      };
    };

    xdg = {
      enable = true;

      # Default applications
      mimeApps = {
        enable = true;

        # See desktop files in /run/current-system/sw/share/applications
        defaultApplications = {
          "text/html" = "firefox.desktop";
          "application/pdf" = "org.pwmt.zathura.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
        };
      };
    };

    gtk = {
      enable = true;

      iconTheme = {
        #package = pkgs.vimix-icon-theme;
        #name = "Vimix";

        name = "Flat-Remix-Teal-Dark";
        package = pkgs.flat-remix-icon-theme;
      };

      theme = {
        #package = pkgs.vimix-gtk-themes;

        name = "FlatColor-base16";
        package =
          let
            gtk2-theme = config.scheme {
              templateRepo = inputs.base16-gtk;
              target = "gtk-2";
            };

            gtk3-theme = config.scheme {
              templateRepo = inputs.base16-gtk;
              target = "gtk-3";
            };
          in
          sysCfg.pkgs.flatcolor-gtk-theme.overrideAttrs (oldAttrs: {
            # Build instructions: https://github.com/Misterio77/base16-gtk-flatcolor
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

    home.packages = with pkgs // sysCfg.pkgs; [
      # Required for gtk: https://github.com/nix-community/home-manager/issues/3113
      dconf

      # For debugging themes
      lxappearance-xwayland

      # So that links open in a browser when clicked from other applications
      # (e.g. vscode)
      xdg-utils

      # File manager
      pcmanfm
      xfce.thunar

      # USB installer
      ventoy-bin

      # Testing
      kopia # Backup tool
      ddcutil
      ddcui

      # Signal
      signal-desktop
    ];

    services = {
      # Bluetooth controls
      blueman-applet.enable = cfg.bluetooth.enable;

      # Enable red-shifted nightime display
      gammastep = {
        enable = true;
        provider = "geoclue2";
        tray = true;
      };

      # File syncing
      syncthing.enable = true;


      # FUTURE: this doesn't work
      # https://github.com/nix-community/home-manager/issues/1454
      # gnome-keyring.enable = true;
    };

    systemd.user.startServices = "sd-switch";
  };
}
