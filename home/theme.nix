{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  tintyDataDir = "${config.home.homeDirectory}/.local/share/tinted-theming/tinty";
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

      extraLuaConfig = ''
        -- Theme
        -- https://github.com/tinted-theming/tinted-nvim
        vim.opt.termguicolors = true
        require('tinted-colorscheme').setup(nil, {
          supports = {
            tinty = true,
            live_reload = true,
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

  # Sync tinty repos and apply theme on activation
  home.activation.tinty = lib.hm.dag.entryAfter ["writeBoundary"] ''
    tinty_bin="${pkgs.tinty}/bin/tinty"
    config_file="$HOME/.config/tinted-theming/tinty/config.toml"
    data_dir="$HOME/.local/share/tinted-theming/tinty"

    mkdir -p "$data_dir"

    if [ -L "$config_file" ]; then
      # Ensure git, fish, and tmux are available (needed on nix-on-droid)
      export PATH="${pkgs.git}/bin:${pkgs.fish}/bin:${pkgs.tmux}/bin:$PATH"
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
        run "$tinty_bin" apply "base24-wild-cherry"
      fi
    fi
  '';

  xdg.configFile = {
    "tinted-theming/tinty/config.toml".source = (pkgs.formats.toml {}).generate "tinty-config" {
      shell = "fish -c '{}'";
      default-scheme = "base24-wild-cherry";
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
        # Waybar
        {
          name = "base16-waybar";
          path = "https://github.com/mnussbaum/base16-waybar";
          themes-dir = "colors";
          revision = "master";
          hook = "command -v waybar >/dev/null; and pkill waybar; and waybar &; disown";
          supported-systems = ["base16" "base24"];
        }
        # Mako notifications
        {
          name = "base16-mako";
          path = "https://github.com/Eluminae/base16-mako";
          themes-dir = "colors";
          revision = "master";
          hook = "command -v makoctl >/dev/null; and makoctl reload";
          supported-systems = ["base16" "base24"];
        }
        # Wofi launcher
        {
          name = "base16-wofi";
          path = "https://git.sr.ht/~knezi/base16-wofi";
          themes-dir = "themes";
          revision = "master";
          # No hook needed - wofi reads CSS on each launch
          supported-systems = ["base16" "base24"];
        }
        # GTK3/4 theme colors (imported via ~/.config/gtk-{3,4}.0/gtk.css)
        {
          name = "base16-gtk";
          path = "https://github.com/tinted-theming/base16-gtk-flatcolor";
          themes-dir = "gtk-3";
          revision = "main";
          theme-file-extension = "-gtk.css";
          # Toggle gsettings to trigger GTK apps to reload CSS
          hook = "test -f \"$TINTY_THEME_FILE_PATH\"; and mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0; and cp \"$TINTY_THEME_FILE_PATH\" ~/.config/gtk-3.0/gtk.css; and cp \"$TINTY_THEME_FILE_PATH\" ~/.config/gtk-4.0/gtk.css; and command -v dconf >/dev/null; and dconf write /org/gnome/desktop/interface/color-scheme \"'prefer-light'\"; and sleep 0.1; and dconf write /org/gnome/desktop/interface/color-scheme \"'prefer-dark'\"";
          supported-systems = ["base16" "base24"];
        }
      ];
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
        padding:10px;
        margin-top: -22px;
      }

      #text {
        padding: 5px;
        color: white;
      }
    '';

  };
}
