{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  tintyDataDir = "${config.home.homeDirectory}/.local/share/tinted-theming/tinty";
  defaultScheme = "base16-tomorrow-night";

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

    # Waybar theme: import colors from tinty-generated CSS
    waybar.style = mkBefore ''
      @import url("file://${tintyDataDir}/artifacts/base16-waybar-colors-file.css");
    '';
  };

  services = {
    # Mako theme: include colors from tinty-generated config
    mako.settings = {
      include = "${tintyDataDir}/artifacts/base16-mako-colors-file.config";
    };
  };

  # GTK theme - FlatColor with colors from user CSS
  gtk.theme = {
    name = "FlatColor";
    package = pkgs.dlo9.flatcolor-gtk-theme;
  };

  gtk.gtk4.theme = config.gtk.theme;

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

  xdg.configFile = {
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

      items =
        [
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
        ]
        # Waybar
        ++ optional config.programs.waybar.enable {
          name = "base16-waybar";
          path = "https://github.com/mnussbaum/base16-waybar";
          themes-dir = "colors";
          revision = "master";
          hook = "command -v waybar >/dev/null; and pkill waybar; and waybar &; disown";
          supported-systems = ["base16" "base24"];
        }
        # Mako notifications
        ++ optional config.services.mako.enable {
          name = "base16-mako";
          path = "https://github.com/Eluminae/base16-mako";
          themes-dir = "colors";
          revision = "master";
          hook = "command -v makoctl >/dev/null; and makoctl reload";
          supported-systems = ["base16" "base24"];
        }
        # Wofi launcher
        ++ optional config.programs.wofi.enable {
          name = "base16-wofi";
          path = "https://git.sr.ht/~knezi/base16-wofi";
          themes-dir = "themes";
          revision = "master";
          # No hook needed - wofi reads CSS on each launch
          supported-systems = ["base16" "base24"];
        }
        # GTK3/4 theme colors (imported via ~/.config/gtk-{3,4}.0/gtk.css)
        ++ optional config.gtk.enable {
          name = "base16-gtk";
          path = "https://github.com/tinted-theming/base16-gtk-flatcolor";
          themes-dir = "gtk-3";
          revision = "main";
          theme-file-extension = "-gtk.css";
          # Toggle gsettings to trigger GTK apps to reload CSS
          hook = "test -f \"$TINTY_THEME_FILE_PATH\"; and mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0; and cp \"$TINTY_THEME_FILE_PATH\" ~/.config/gtk-3.0/gtk.css; and cp \"$TINTY_THEME_FILE_PATH\" ~/.config/gtk-4.0/gtk.css; and command -v dconf >/dev/null; and dconf write /org/gnome/desktop/interface/color-scheme \"'prefer-light'\"; and sleep 0.1; and dconf write /org/gnome/desktop/interface/color-scheme \"'prefer-dark'\"";
          supported-systems = ["base16" "base24"];
        };
    };

    # Wofi styles: import colors from tinty-generated CSS
    "wofi/style.css".text = ''
      @import url("${tintyDataDir}/artifacts/base16-wofi-themes-file.css");

      *{
        font-family: ${config.font.family};
        font-size: ${builtins.toString config.font.size}px;
      }

      window {
        border: 1px solid;
      }

      #input {
        margin-bottom: 15px;
        padding:3px;
        border-radius: 5px;
        border:none;
      }

      #outer-box {
        margin: 5px;
        padding:15px;
      }

      #text {
        padding: 5px;
      }
    '';

    "wofi/style.widgets.css".text = ''
      @import url("${tintyDataDir}/artifacts/base16-wofi-themes-file.css");

      *{
        font-family: ${config.font.family};
        font-size: ${builtins.toString config.font.size}px;
      }

      #window {
        border: 1px solid white;
        margin: 0px 5px 0px 5px;
      }

      #outer-box {
        margin: 5px;
        padding: 10px;
      }

      #text {
        padding: 5px;
        color: white;
      }
    '';
  };
}
