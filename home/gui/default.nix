{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with types;
with builtins; let
  cfg = config.home.gui;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in {
  imports = [
    ./sway
  ];

  options.home.gui = {
    enable = mkEnableOption "user graphical programs" // {default = true;};
    bluetooth.enable = mkEnableOption "bluetooth applet" // {default = false;};
  };

  config = mkIf cfg.enable {
    home.pointerCursor = {
      name = "Numix-Cursor-Light";
      package = pkgs.numix-cursor-theme;
      gtk.enable = isLinux;
      x11.enable = false;
    };

    programs = {
      # Utils
      feh.enable = isLinux;

      ####################
      ### Web browsers ###
      ####################

      qutebrowser.enable = isLinux;

      chromium = {
        enable = isLinux;
        extensions = [
          {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # ublock origin
        ];
      };

      firefox = {
        enable = isLinux;

        profiles = {
          # Set dev edition profile to the same as default release
          dev-edition-default = {
            path = "default";
            id = 1;
          };

          # To change an existing profile called `48gm70ji.default-release` into default:
          # cd ~/.mozilla/firefox; rg -l 48gm70ji default | xargs -I {} sed -i 's#48gm70ji.default-release#default#g' {}
          default-release = {
            id = 0;
            isDefault = true;
            path = "default";

            # https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/generated-firefox-addons.nix
            extensions = with config.nur.repos.rycee.firefox-addons; [
              #amazon-band-detector
              auto-tab-discard
              bitwarden
              #base16
              facebook-container
              #highlight-all
              honey
              #surfshark
              tab-session-manager
              tree-style-tab
              ublock-origin
              vimium
            ];

            search = {
              force = true;
              default = "DuckDuckGo";
              order = [
                "DuckDuckGo"
                "Google"
              ];

              engines = {
                "Nix Packages" = {
                  urls = [
                    {
                      template = "https://search.nixos.org/packages";
                      params = [
                        {
                          name = "type";
                          value = "packages";
                        }
                        {
                          name = "query";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];

                  icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                  definedAliases = ["@np"];
                };

                "NixOS Wiki" = {
                  urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
                  iconUpdateURL = "https://nixos.wiki/favicon.png";
                  updateInterval = 24 * 60 * 60 * 1000; # every day
                  definedAliases = ["@nw"];
                };
              };
            };

            settings = {
              # See userChrome below
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };

            # https://gist.github.com/ruanbekker/f800e098936b27c7cf956c56005fe362
            userChrome = ''
              #main-window[tabsintitlebar="true"]:not([extradragspace="true"]) #TabsToolbar > .toolbar-items {
                opacity: 0;
                pointer-events: none;
              }

              #main-window:not([tabsintitlebar="true"]) #TabsToolbar {
                visibility: collapse !important;
              }

              #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
                display: none;
              }

              .tab {
                margin-left: 1px;
                margin-right: 1px;
              }
            '';
          };
        };
      };

      vim.plugins = with pkgs.vimPlugins; [
        # Fix copy to system clipboard on wayland
        vim-wayland-clipboard
      ];

      alacritty = {
        enable = true;

        # https://github.com/alacritty/alacritty/blob/master/alacritty.yml
        settings =
          {
            window.opacity = 0.9;
            decorations = "full";
            font = {
              normal.family = "NotoSansM Nerd Font Mono";
              #size = 11;
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
          // (pkgs.fromYAML (config.scheme inputs.base16-alacritty));
      };

      vscode = {
        enable = true;

        # Don't enable these settings, or all settings must be managed by nix
        # enableUpdateCheck = false;
        # enableExtensionUpdateCheck = false;

        # Allow extension installations/updates
        mutableExtensionsDir = true;

        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide

          # Enables SSH into a Nix remote host:
          # https://nixos.wiki/wiki/Visual_Studio_Code#Nix-sourced_VS_Code_to_NixOS_host
          ms-vscode-remote.remote-ssh
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
      enable = isLinux;

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
          pkgs.flatcolor-gtk-theme.overrideAttrs (oldAttrs: {
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
          # For debugging themes
          lxappearance-xwayland

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
          inetutils

          # HDD info
          smartmontools

          unstable.anytype
        ])

        [
          # Required for gtk: https://github.com/nix-community/home-manager/issues/3113
          dconf

          # So that links open in a browser when clicked from other applications
          # (e.g. vscode)
          xdg-utils

          # Notes app
          obsidian
        ]
      ];

    services = {
      # Bluetooth controls
      blueman-applet.enable = cfg.bluetooth.enable;

      # Enable red-shifted nightime display
      gammastep = {
        enable = isLinux;
        provider = "geoclue2";
        tray = true;
      };

      # File syncing
      syncthing.enable = isLinux;

      # Screenshots
      # Disabled since this isn't working on sway right now
      #flameshot.enable = true;
    };

    systemd.user.startServices = "sd-switch";
  };
}
