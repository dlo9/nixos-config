{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  ...
}:
with lib; {
  config = mkIf config.graphical.enable {
    programs = {
      chromium = {
        enable = mkDefault isLinux;
        package = pkgs.google-chrome;

        extensions = [
          {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # ublock origin
        ];
      };

      firefox = {
        enable = mkDefault isLinux;

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
            extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
              #amazon-band-detector
              auto-tab-discard
              bitwarden
              #base16
              facebook-container
              #highlight-all
              #honey
              #surfshark
              tab-session-manager
              tree-style-tab
              ublock-origin
              vimium
            ];

            search = {
              force = true;
              default = "ddg";
              order = [
                "ddg"
                "google"
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
                  icon = "https://nixos.wiki/favicon.png";
                  updateInterval = 24 * 60 * 60 * 1000; # every day
                  definedAliases = ["@nw"];
                };
              };
            };

            settings = {
              # See userChrome below
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "app.update.auto" = false;
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
    };

    xdg.mimeApps.defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
}
