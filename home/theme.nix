{
  config,
  pkgs,
  lib,
  isLinux,
  osConfig,
  ...
}:
with lib; let
  tintyDataDir = "${config.home.homeDirectory}/.local/share/tinted-theming/tinty";
  defaultScheme = "base16-tomorrow-night";

  # Where DankMaterialShell runs, and therefore where matugen owns the GTK and
  # Qt palettes. Matches the guard on home/graphical/dms.nix.
  dmsThemed = config.graphical.enable && isLinux;

  # Renders a revdiff theme from the current scheme, mapped per the base16
  # styling guide. Runs as a tinty global hook, which exposes the palette
  # as TINTY_SCHEME_PALETTE_* variables. revdiff re-reads themes on
  # startup, so the next invocation picks up the new theme
  revdiff-tinty-theme = pkgs.writeShellApplication {
    name = "revdiff-tinty-theme";
    text = ''
      # revdiff always resolves ~/.config, ignoring XDG_CONFIG_HOME
      themes_dir="$HOME/.config/revdiff/themes"
      mkdir -p "$themes_dir"

      # "#rrggbb" for a palette color, e.g.: hex BASE0D
      hex() {
        local r="TINTY_SCHEME_PALETTE_$1_HEX_R"
        local g="TINTY_SCHEME_PALETTE_$1_HEX_G"
        local b="TINTY_SCHEME_PALETTE_$1_HEX_B"

        echo "#''${!r}''${!g}''${!b}"
      }

      # Blend a color into the background for subtle line tints, e.g.: mix BASE0B 15
      mix() {
        local color="$1" pct="$2"
        local out="#"

        local ch fg_var bg_var fg bg
        for ch in R G B; do
          fg_var="TINTY_SCHEME_PALETTE_''${color}_RGB_''${ch}"
          bg_var="TINTY_SCHEME_PALETTE_BASE00_RGB_''${ch}"
          fg="''${!fg_var}"
          bg="''${!bg_var}"

          out+=$(printf '%02x' $(((fg * pct + bg * (100 - pct)) / 100)))
        done

        echo "$out"
      }

      # Syntax highlighting uses chroma's named styles, so pick the closest
      # match for the scheme, falling back on the light/dark variant
      case "''${TINTY_SCHEME_SLUG:-}" in
        gruvbox*light*) chroma="gruvbox-light" ;;
        gruvbox*) chroma="gruvbox" ;;
        github*light*) chroma="github" ;;
        github*) chroma="github-dark" ;;
        tokyo-night*day*) chroma="tokyonight-day" ;;
        tokyo-night*) chroma="tokyonight-night" ;;
        catppuccin*latte*) chroma="catppuccin-latte" ;;
        catppuccin*frappe*) chroma="catppuccin-frappe" ;;
        catppuccin*macchiato*) chroma="catppuccin-macchiato" ;;
        catppuccin*) chroma="catppuccin-mocha" ;;
        solarized*light*) chroma="solarized-light" ;;
        solarized*) chroma="solarized-dark" ;;
        rose-pine*dawn*) chroma="rose-pine-dawn" ;;
        rose-pine*moon*) chroma="rose-pine-moon" ;;
        rose-pine*) chroma="rose-pine" ;;
        dracula*) chroma="dracula" ;;
        nord*) chroma="nord" ;;
        monokai*) chroma="monokai" ;;
        onedark* | one-dark*) chroma="onedark" ;;
        *)
          chroma="github-dark"
          if [ "''${TINTY_SCHEME_VARIANT:-dark}" = "light" ]; then
            chroma="github"
          fi
          ;;
      esac

      cat > "$themes_dir/tinty" << EOF
      # name: tinty
      # description: generated from the current tinty scheme ($TINTY_SCHEME_ID) - do not edit

      chroma-style = $chroma
      color-accent = $(hex BASE0D)
      color-border = $(hex BASE02)
      color-normal = $(hex BASE05)
      color-muted = $(hex BASE03)
      color-selected-fg = $(hex BASE00)
      color-selected-bg = $(hex BASE0D)
      color-annotation = $(hex BASE0A)
      color-cursor-fg = $(hex BASE0A)
      color-add-fg = $(hex BASE0B)
      color-add-bg = $(mix BASE0B 15)
      color-remove-fg = $(hex BASE08)
      color-remove-bg = $(mix BASE08 15)
      color-modify-fg = $(hex BASE09)
      color-modify-bg = $(mix BASE09 15)
      color-status-fg = $(hex BASE00)
      color-status-bg = $(hex BASE0D)
      color-search-fg = $(hex BASE00)
      color-search-bg = $(hex BASE0A)
      EOF
    '';
  };
in {
  options = {
    font.family = mkOption {
      type = types.nonEmptyStr;
      default = osConfig.font.family;
    };

    font.size = mkOption {
      type = types.ints.positive;
      default = osConfig.font.size;
    };

    wallpapers = mkOption {
      type = types.attrsOf types.package;
      readOnly = true;

      default = rec {
        default = spaceman;

        spaceman = builtins.fetchurl {
          name = "spaceman.jpg";
          url = https://forum.endeavouros.com/uploads/default/original/3X/c/d/cdb27eeb063270f9529fae6e87e16fa350bed357.jpeg;
          sha256 = "02b892xxwyzzl2xyracnjhhvxvyya4qkwpaq7skn7blg51n56yz2";
        };

        #valley = fetchurl {
        #  name = "elementary-os-7";
        #  url = https://raw.githubusercontent.com/elementary/wallpapers/3f36a60cbb9b8b2a37d0bc5129365ac2ac7acf98/backgrounds/Photo%20of%20Valley.jpg;
        #  sha256 = "0xvdyg4wa1489h5z6p336v5bk2pi2aj0wpsp2hdc0x6j4zpxma7k";
        #};

        # Hash keeps changing
        #pink-sunset = fetchurl {
        #  name = "pink-sunset";
        #  url = https://cutewallpaper.org/22/retro-neon-race-4k-wallpapers/285729412.jpg;
        #  sha256 = "0p6z31gh552rk4w99gbvr3hvwadfrv6h97k41qdbb9mxy7wc9brz";
        #};

        #mountain-milky-way = fetchurl {
        #  name = "mountain-milky-way";
        #  url = https://images.squarespace-cdn.com/content/v1/5de93a2db580764b4f6963f9/10757377-0072-4864-bcf9-17bc4df0d252/GOLD%C2%A9Jake+Mosher_The+Grand+Tetons.jpg;
        #  sha256 = "19l11x94qyc7mqwkrr8l2llimqp7v38ikd66k3pvma0vb3773js3";
        #};

        #mountain-reflection = fetchurl {
        #  name = "mountain-reflection";
        #  url = https://images.squarespace-cdn.com/content/v1/5de93a2db580764b4f6963f9/956426d5-8a84-493d-af76-fee19de5a29d/SILVER%C2%A9Beatrice+Wong_Parallel+universe.jpg;
        #  sha256 = "173spa2j1fbvgzag3lw3y3sl7zpags4mixrwx7fv0brmp483v8g7";
        #};

        # Blocked by cloudflare
        #wr-134-wolf-nebula = fetchurl {
        #  name = "";
        #  url = https://media.invisioncic.com/r307508/monthly_2024_09/WR134HOO.jpg.6a54efbab22a1e32d98ab035856280ab.jpg;
        #  sha256 = "38271ff1945e3c717a29b242919326cd014dea8b99932fa3262adccc622e8f9b";
        #};
      };
    };
  };

  config = {
    home.sessionVariables = {
      TINTED_TMUX_OPTION_STATUSBAR = "1";
    };

    home.packages = with pkgs; [
      tinty
    ];

    programs = {
      neovim = {
        plugins = with pkgs.vimPlugins; [
          tinted-nvim
        ];

        initLua = ''
          -- Theme
          -- https://github.com/tinted-theming/tinted-nvim
          require('tinted-nvim').setup({
            selector = {
              enabled = true,
              mode = "file",
              watch = true,
            },
          })
        '';
      };

      fish.interactiveShellInit = ''
        #############
        ### Theme ###
        #############

        # Load theme on startup
        sh ~/.local/share/tinted-theming/tinty/tinted-shell-scripts-file.sh

        # Instant reload via universal variable (set by tinty tinted-shell hook)
        function __reload_theme --on-variable theme_trigger
          sh ~/.local/share/tinted-theming/tinty/tinted-shell-scripts-file.sh
        end
      '';

      alacritty.settings.general.import = ["~/.local/share/tinted-theming/tinty/artifacts/tinted-terminal-themes-alacritty-file.toml"];
    };

    # GTK and Qt are themed by DMS's matugen, so all of this only applies where
    # the shell runs. This file is imported on headless and darwin hosts too.
    gtk = mkIf dmsThemed {
      # The theme is only ever a carrier for a palette here: matugen's
      # dank-colors.css defines the libadwaita color names and nothing else, so
      # GTK3 needs adw-gtk3 to map those onto widgets.
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };

      # GTK4/libadwaita apps take the @define-colors straight from user CSS;
      # adw-gtk3 here would layer a second restyle on the one libadwaita applies.
      gtk4.theme = null;

      # Declares what DMS's one-shot "Apply GTK Colors" button would do, so the
      # wiring survives a fresh checkout. matugen writes dank-colors.css next to
      # these files on startup and on every theme change; until it exists GTK
      # warns and falls back to the theme's own colors.
      gtk3.extraCss = ''
        @import url("dank-colors.css");
      '';

      gtk4.extraCss = ''
        @import url("dank-colors.css");
      '';
    };

    # DMS points qt6ct at the palette matugen writes, but its script is gated
    # on `command -v qt6ct` and reports failure without it.
    #
    # The name is the literal "qt6ct", not the documented "qtct" preset:
    # home-manager maps that to QT_QPA_PLATFORMTHEME=qt5ct, and qtbase 6.11 has
    # no QT_QPA_PLATFORMTHEME_QT6 fallback to pick up the Qt6 side. DMS's icon
    # theme picker also warns unless it sees exactly "qt6ct" or "gtk3". qt5ct
    # is left out since Qt5 apps ignore the variable at this value anyway.
    #
    # qt6ct.conf itself stays unmanaged: DMS sed's it in place, which a store
    # symlink would defeat. Same as settings.json in home/graphical/dms.nix.
    qt = mkIf dmsThemed {
      enable = true;

      platformTheme = {
        name = "qt6ct";
        package = pkgs.qt6Packages.qt6ct;
      };
    };

    # Sync tinty repos and apply theme on activation
    home.activation.tinty = lib.hm.dag.entryAfter ["writeBoundary"] ''
      tinty_bin="${pkgs.tinty}/bin/tinty"
      config_file="$HOME/.config/tinted-theming/tinty/config.toml"
      data_dir="$HOME/.local/share/tinted-theming/tinty"

      mkdir -p "$data_dir"

      if [ -L "$config_file" ]; then
        # Ensure git, fish, and tmux are available (needed on nix-on-droid)
        export PATH="${pkgs.git}/bin:${config.programs.fish.package}/bin:${pkgs.tmux}/bin:$PATH"
        # Ignore global git config that may rewrite HTTPS URLs to SSH
        export GIT_CONFIG_GLOBAL=/dev/null
        export GIT_CONFIG_SYSTEM=/dev/null

        # Always run install/update - idempotent and will skip already-installed items
        run "$tinty_bin" install
        run "$tinty_bin" update

        # Re-apply current theme to populate files for new items, or apply default if unset
        current_scheme=$("$tinty_bin" current 2>/dev/null | tr -d '"' || echo "")
        if [ -n "$current_scheme" ]; then
          run "$tinty_bin" apply "$current_scheme"
        else
          run "$tinty_bin" apply "${defaultScheme}"
        fi
      fi
    '';

    xdg.configFile = mkMerge [
      {
        "tinted-theming/tinty/config.toml".source = (pkgs.formats.toml {}).generate "tinty-config" {
          shell = "fish -c '{}'";

          default-scheme = defaultScheme;

          # Global hooks, run after every `tinty apply`
          hooks = optional config.developer-tools.enable "${revdiff-tinty-theme}/bin/revdiff-tinty-theme";

          preferred-schemes = [
            "base16-gruvbox-dark"
            "base16-github-dark"
            "base24-wild-cherry"
            "base16-tokyo-night-dark"
            "base16-woodland"
            "base16-tomorrow-night"
            "base16-atelier-seaside"
            "base16-gigavolt"
          ];

          items = [
            # Shell
            {
              name = "tinted-shell";
              path = "https://github.com/tinted-theming/tinted-shell";
              themes-dir = "scripts";
              hook = "set -U theme_trigger (date +%s)";
              supported-systems = ["base16" "base24"];
            }
            # Neovim
            {
              name = "base16-vim";
              path = "https://github.com/tinted-theming/base16-vim";
              themes-dir = "colors";
              supported-systems = ["base16" "base24"];
            }
            # Alacritty
            {
              name = "tinted-terminal";
              path = "https://github.com/tinted-theming/tinted-terminal";
              themes-dir = "themes/alacritty";
              supported-systems = ["base16" "base24"];
            }
            # Tmux
            {
              name = "tmux";
              path = "https://github.com/tinted-theming/tinted-tmux";
              themes-dir = "colors";
              hook = ''tmux source-file "$TINTY_THEME_FILE_PATH" 2>/dev/null'';
              supported-systems = ["base16" "base24"];
            }
          ];
        };
      }

      # Let activation overwrite these rather than refuse to switch: DMS's
      # "Apply GTK Colors" button replaces gtk.css with a symlink home-manager
      # doesn't own, and its collision check only backs up regular files, so one
      # press would wedge every subsequent rebuild. Safe because the declarative
      # import above says the same thing the button does.
      #
      # mkIf wraps the whole attrset, not the values: an attribute *name* here
      # declares a file with no source on hosts where the gtk module writes
      # neither.
      (mkIf dmsThemed {
        "gtk-3.0/gtk.css".force = true;
        "gtk-4.0/gtk.css".force = true;
      })
    ];
  };
}
