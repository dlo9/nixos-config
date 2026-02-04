{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  imports = [
    inputs.base16.homeManagerModule
  ];

  home.sessionVariables = {
    TINTED_TMUX_OPTION_STATUSBAR = "1";
  };

  home.packages = with pkgs; [
    tinty
  ];

  # TODO: try out github.com/nix-community/stylix

  # Available schemes: https://github.com/tinted-theming/schemes
  scheme.yaml = "${inputs.tinted-theming}/base24/wild-cherry.yaml";
  scheme.use-ifd = "auto";

  programs = {
    vim = {
      settings = {
        background = "dark";
      };

      plugins = with pkgs.vimPlugins; [
        tinted-vim
        #   vim-airline-themes
      ];

      extraConfig = ''
        """""""""""
        "" Theme ""
        """""""""""

        " https://github.com/tinted-theming/tinted-vim
        let tinted_background_transparent=1
        set termguicolors
        source ~/.local/share/tinted-theming/tinty/base16-vim-colors-file.vim

        " Autoreload
        set updatetime=10000 " every 10 seconds

        function! CheckThemeFile()
          let l:theme_file = expand('~/.local/share/tinted-theming/tinty/base16-vim-colors-file.vim')
          let l:mtime = getftime(l:theme_file)
          if l:mtime != get(g:, 'theme_mtime', 0)
              let g:theme_mtime = l:mtime
              execute 'source' l:theme_file
              echom "Theme reloaded!"
          endif
        endfunction

        augroup ThemeWatch
            autocmd!
            autocmd CursorHold,CursorHoldI * call CheckThemeFile()
        augroup END
      '';
    };

    fish.interactiveShellInit = ''
      #############
      ### Theme ###
      #############

      # Set theme on startup
      sh ~/.local/share/tinted-theming/tinty/tinted-shell-scripts-file.sh

      # Auto reload with: set -U theme_trigger (date +%s)
      function reload_theme --on-variable theme_trigger
        sh ~/.local/share/tinted-theming/tinty/tinted-shell-scripts-file.sh
      end
    '';

    #alacritty.settings.general.import = ["~/.local/share/tinted-theming/tinty/tinted-terminal-themes-alacritty-file.toml"];

    waybar.style = ''
      /*****************/
      /***** Theme *****/
      /*****************/

      ${readFile (config.scheme inputs.base16-waybar)}
    '';
  };

  services = {
    # TODO: removed, have to use mako.settings
    #mako.extraConfig = readFile (config.scheme inputs.base16-mako);
  };

  gtk.theme = {
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

  xdg.configFile = {
    "tinted-theming/tinty/config.toml".source = (pkgs.formats.toml {}).generate "tinty-config" {
      # Initialize with: tinty install && tinty apply base24-wild-cherry
      shell = "fish -c '{}'";
      default-scheme = "base24-wild-cherry";
      preferred-schemes = [
        "base16-gruvbox-dark"
        "base16-gruvbox-light"
        "base16-github-dark"
        "base24-wild-cherry"
        "base16-tokyo-night-dark"
        "base16-woodland"
        "base16-tomorrow-night"
        "base16-atelier-seaside"
        "base16-gigavolt"
      ];

      items = [
        {
          name = "tinted-shell";
          path = "https://github.com/tinted-theming/tinted-shell";
          themes-dir = "scripts";
          hook = "set -U theme_trigger (date +%s)";
          supported-systems = ["base16" "base24"];
        }
        {
          name = "base16-vim";
          path = "https://github.com/tinted-theming/base16-vim";
          themes-dir = "colors";
          supported-systems = ["base16" "base24"];
        }
        {
          name = "tinted-terminal";
          path = "https://github.com/tinted-theming/tinted-terminal";
          themes-dir = "themes/alacritty";
          supported-systems = ["base16" "base24"];
        }
        {
          name = "tmux";
          path = "https://github.com/tinted-theming/tinted-tmux";
          themes-dir = "colors";
          hook = ''tmux source-file "$TINTY_THEME_FILE_PATH" 2>/dev/null'';
          supported-systems = ["base16" "base24"];
        }
      ];
    };

    "wofi/style.css".text = ''
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

      ${readFile (config.scheme inputs.base16-wofi)}
    '';

    "wofi/style.widgets.css".text = ''
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

      ${readFile (config.scheme inputs.base16-wofi)}
    '';
  };
}
