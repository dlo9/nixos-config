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

  scheme = "${inputs.base16-atelier}/atelier-seaside.yaml";
  #scheme = "${inputs.base16-unclaimed}/apathy.yaml";

  programs = {
    vim = {
      settings = {
        background = "dark";
      };

      plugins = with pkgs.vimPlugins; [
        base16-vim
        vim-airline-themes
      ];

      extraConfig = ''
        """""""""""
        "" Theme ""
        """""""""""

        let base16colorspace=256
        colorscheme base16-${config.scheme.slug}
        let g:airline_theme='base16_${builtins.replaceStrings ["-"] ["_"] config.scheme.slug}'
      '';
    };

    fish.interactiveShellInit = ''
      # Theme
      # Babelfish can't handle the official shell theme
      for f in ${inputs.base16-fish-shell}/functions/__*.fish
        source $f
      end

      source ${config.scheme inputs.base16-fish-shell}
      base16-${config.scheme.scheme-slug}
    '';

    alacritty.settings = importTOML (config.scheme inputs.base16-alacritty);

    waybar.style = ''
      /*****************/
      /***** Theme *****/
      /*****************/

      ${readFile (config.scheme inputs.base16-waybar)}
    '';

    swaylock.settings = with config.scheme.withHashtag; let
      # https://github.com/Misterio77/dotfiles/blob/sway/home/.config/sway/swaylock.sh
      insideColor = base01;
      ringColor = base02;
      errorColor = base08;
      clearedColor = base0C;
      highlightColor = base0B;
      verifyingColor = base09;
      textColor = base07;
    in {
      indicator-caps-lock = true;
      image = "${config.wallpapers.default}";
      scaling = "fill";
      font = config.font.family;
      font-size = 20;
      indicator-radius = 115;

      ring-color = ringColor;
      inside-wrong-color = errorColor;
      ring-wrong-color = errorColor;
      key-hl-color = highlightColor;
      bs-hl-color = errorColor;
      ring-ver-color = verifyingColor;
      inside-ver-color = verifyingColor;
      inside-color = insideColor;
      text-color = textColor;
      text-clear-color = insideColor;
      text-ver-color = insideColor;
      text-wrong-color = insideColor;
      text-caps-lock-color = insideColor;
      inside-clear-color = clearedColor;
      ring-clear-color = clearedColor;
      inside-caps-lock-color = verifyingColor;
      ring-caps-lock-color = ringColor;
      separator-color = ringColor;
    };
  };

  services = {
    mako.extraConfig = readFile (config.scheme inputs.base16-mako);
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
