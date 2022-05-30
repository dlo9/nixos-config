# Home manager configuration
# - Manual: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
# - Config: https://rycee.gitlab.io/home-manager/options.html

{ config, pkgs, lib, inputs, sysCfg, ... }:

with lib;
with types;

let
  cfg = config.home;

  weather-module = pkgs.writeScript "wofi-weather.sh" ''
    #!/bin/sh
    # Format options: https://github.com/chubin/wttr.in

    LOCATION="$1"
    WEATHER="$(curl -s "wttr.in/$LOCATION?format=%l|%c|%C|%t|%f|%w" | sed -r -e 's/\s*\|\s*/|/g' -e 's/\+([0-9.]+°)/\1/g')"
    LOCATION=$(echo "$WEATHER" | awk -F '|' '{print $1}' | sed 's/,/, /g')
    ICON=$(echo "$WEATHER" | awk -F '|' '{print $2}')
    DESCRIPTION=$(echo "$WEATHER" | awk -F '|' '{print $3}')
    TEMP=$(echo "$WEATHER" | awk -F '|' '{print $4}')
    FEELS_LIKE=$(echo "$WEATHER" | awk -F '|' '{print $5}')
    WIND=$(echo "$WEATHER" | awk -F '|' '{print $6}')

    printf '{"text":"%s %s", "tooltip":"%s: %s, %s, %s", "class":"", "percentage":""}' "$ICON" "$FEELS_LIKE" "$LOCATION" "$DESCRIPTION" "$TEMP" "$WIND"
  '';

  power-module = pkgs.writeScript "power-menu.sh" ''
    #!/bin/sh

    entries="Logout Suspend Reboot Shutdown"

    selected=$(printf '%s\n' $entries | wofi --conf=$HOME/.config/wofi/config.power --style=$HOME/.config/wofi/style.widgets.css | awk '{print tolower($1)}')

    case $selected in
      logout)
        swaymsg exit;;
      suspend)
        exec systemctl suspend;;
      reboot)
        exec systemctl reboot;;
      shutdown)
        exec systemctl poweroff -i;;
    esac
  '';
in
{
  imports = [ inputs.base16.homeManagerModule ];

  options.home = {
    enable = mkEnableOption "user home management" // { default = true; };
    enableGui = mkEnableOption "graphical programs" // { default = true; };
  };

  config = mkIf cfg.enable {
    scheme = "${inputs.base16-atelier}/atelier-seaside.yaml";
    #scheme = "${inputs.base16-unclaimed}/apathy.yaml";

    home = {
      sessionPath = [
        "$HOME/.cargo/bin"
        "$HOME/.local/bin"
      ];

      sessionVariables = {
        EDITOR = "${config.programs.vim.package}/bin/vim";
      };

      pointerCursor = {
        name = "Numix-Cursor-Light";
        package = pkgs.numix-cursor-theme;
      };
    };

    # Allow user-installed fonts
    fonts.fontconfig.enable = true;

    programs = {
      git = {
        enable = true;
        userName = "David Orchard";
        userEmail = "if_coding@fastmail.com";
        extraConfig = {
          init.defaultBranch = "main";
          pull.ff = "only";
        };
      };

      # TODO: only if GUI
      qutebrowser.enable = true;

      tmux = {
        enable = true;
        sensibleOnTop = true;
        baseIndex = 1;
        clock24 = true;
        keyMode = "vi";
        prefix = "C-b";

        historyLimit = 50000;
        aggressiveResize = true;
        escapeTime = 0;
        terminal = "screen-256color";

        # Spawn a new session when attaching and none exist
        newSession = true;

        plugins = with pkgs.tmuxPlugins // sysCfg.pkgs.tmuxPlugins; [
          {
            plugin = tmux-themepack;
            extraConfig = "set -g @themepack 'powerline/double/purple'";
          }
        ];

        extraConfig = ''
          # Gapless indexing
          set-option -g renumber-windows on

          # easy-to-remember split pane commands
          bind | split-window -h
          bind - split-window -v
          unbind '"'
          unbind %
        '';
      };

      vim = {
        enable = true;

        settings = {
          background = "dark";
          backupdir = [ "$HOME/.cache/vim/backup" ];
          copyindent = true;
          directory = [ "$HOME/.cache/vim/swap" ];
          hidden = true;
          number = true;
          relativenumber = true;
          shiftwidth = 2;
          smartcase = true;
          tabstop = 2;
          undodir = [ "$HOME/.cache/vim/undo" ];
        };


        plugins = with pkgs.vimPlugins // sysCfg.pkgs.vimPlugins; [
          # Statusline
          vim-airline

          # Auto paste mode
          vim-bracketed-paste

          # Autoindent
          vim-yadi

          # Remove extra whitespace
          vim-strip-trailing-whitespace

          # Remember last place
          vim-lastplace

          # Theme
          base16-vim
          vim-airline-themes

          # Autocomplete plugins
          coc-git
          coc-rust-analyzer
          coc-spell-checker
          coc-vimlsp
          coc-yaml
          coc-java
          coc-go
          coc-highlight
          coc-rome # Webby stuff (JS, TS, JSON, HTML, MD, CSS)
          coc-sh
          coc-docker
        ];

        extraConfig = ''
          """""""""""
          "" Theme ""
          """""""""""

          let base16colorspace=256
          colorscheme base16-${config.scheme.slug}
          let g:airline_theme='base16_${builtins.replaceStrings ["-"] ["_"] config.scheme.slug}'

          """""""""""""
          "" Airline ""
          """""""""""""

          " Enable top bar
          let g:airline#extensions#tabline#enabled = 1

          " Use powerline arrows
          let g:airline_powerline_fonts = 1

          " Disable whitespace notification due to improper theming
          let g:airline#extensions#whitespace#enabled = 0

          """""""""""""
          "" General ""
          """""""""""""

          " Command lines to remember
          set history=80

          " Set to auto read when a file is changed from the outside
          set autoread

          " Use system clipboard
          set clipboard=unnamed

          " Spelling
          " Leader is `\`, so type `\+a` for spelling help
          vmap <leader>a <Plug>(coc-codeaction-selected)
          nmap <leader>a <Plug>(coc-codeaction-selected)

          """"""""
          "" UI ""
          """"""""

          " Number of context lines to keep between cursor and top/bottom of window
          set so=7

          " Show available options for command tab completion
          set wildmenu

          "Always show cursor position
          set ruler

          " A buffer becomes hidden when it is abandoned
          set hid

          " Backspace should delete all characters
          set backspace=indent,eol,start

          " Move to next line when at EOL
          set whichwrap+=<,>,h,l

          " Don't redraw while executing macros
          set lazyredraw

          " Use GREP regex characters
          set magic

          " Show matching brackets when cursor is over them
          set showmatch

          " No annoying sound on errors
          set noerrorbells
          set novisualbell
          set t_vb=
          set tm=500

          """"""""""""
          "" Search ""
          """"""""""""

          " Ignore case
          set ignorecase

          " Unless the search contains a capital
          set smartcase

          " Highlight results
          set hlsearch

          " Search as you type
          set incsearch

          """""""""""""""""""
          "" File encoding ""
          """""""""""""""""""

          " Set utf8 as standard encoding
          set encoding=utf8

          " Use Unix as the standard file type
          set ffs=unix,dos,mac

          """"""""""""""""""""""""""""""""""
          "" Text, tab and indent related ""
          """"""""""""""""""""""""""""""""""

          " Try to auto detect and use the indentation of a file when opened.
          autocmd BufRead * DetectIndent

          " Otherwise use file type specific indentation
          filetype plugin indent on

          " Set a fallback here in case detection fails and there is no file type
          " plugin available. You can also omit this, then Vim defaults to tabs.
          set expandtab shiftwidth=2 softtabstop=2

          " You stay in control of your tabstop setting.
          set tabstop=2

          " Backspace removes <tabstop> spaces from the start of the line
          set smarttab

          " Linewrap obeys word boundaries
          set linebreak

          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          " => Moving around, tabs, windows and buffers
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

          " Control+Arrow jumps between words/lines
          map Od <c-left>
          map Ob <c-down>
          map Oa <c-up>
          map Oc <c-right>
          map! Od <c-left>
          map! Ob <c-down>
          map! Oa <c-up>
          map! Oc <c-right>

          " Shift-Tab should behave as expected
          inoremap <Esc>[Z <C-d>

          " TODO: Haven't reviewed past this line
          " Treat long lines as break lines (useful when moving around in them)
          " TODO: doesn't seem to work
          map j gj
          map k gk

          " Disable highlight when <leader><cr> is pressed
          " TODO: doesn't seem to work
          map <silent> <leader><cr> :noh<cr>

          " Faster window jumps
          map <C-j> <C-W>j
          map <C-k> <C-W>k
          map <C-h> <C-W>h
          map <C-l> <C-W>l

          " Close all the buffers
          " TODO: doesn't seem to work (map to q!! or qa if it does?)
          " map <leader>bd :Bclose<cr>
          map <leader>ba :1,1000 bd!<cr>

          " Useful mappings for managing tabs
          map <leader>tn :tabnew<cr>
          map <leader>to :tabonly<cr>
          map <leader>tc :tabclose<cr>
          map <leader>tm :tabmove

          " Remember info about open buffers on close
          " Store up to 1000 lines in each buffer
          set viminfo^=%,<1000

          """"""""""""""""
          """ Filetypes ""
          """"""""""""""""

          autocmd FileType yaml setlocal tabstop=2 expandtab shiftwidth=2 softtabstop=2
          autocmd FileType python setlocal tabstop=4 expandtab shiftwidth=4 softtabstop=4
        '';
      };

      fish = {
        enable = true;

        # FUTURE: use pkgs.fishPlugins.foreign-env
        # https://github.com/nix-community/home-manager/issues/2451
        plugins = [
          {
            # Necessary for sourcing the POSIX shell script for base16-shell
            name = "foreign-env";

            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-foreign-env";
              rev = "dddd9213272a0ab848d474d0cbde12ad034e65bc";
              sha256 = "00xqlyl3lffc5l0viin1nyp819wf81fncqyz87jx8ljjdhilmgbs";
            };
          }
        ];

        interactiveShellInit = ''
          # Theme
          fenv "source ${config.scheme inputs.base16-shell}"
        '';

        functions = {
          fish_user_key_bindings = ''
            # Ctrl-Backspace
            bind \e\[3^ kill-word

            # Ctrl-Delete
            bind \b backward-kill-word

            # Delete 'Ctrl-D to exit' binding, which causes accidental terminal exit
            # when ssh'd pagers hit EOF
            # https://stackoverflow.com/questions/34216850/how-to-prevent-iterm2-from-closing-when-typing-ctrl-d-eof
            # In bash, use:
            # https://unix.stackexchange.com/questions/139115/disable-ctrl-d-window-close-in-terminator-terminal-emulator
            bind --erase --preset \cd
          '';

          fork = ''
            eval "$argv & disown > /dev/null"
          '';

          # TODO: pavil only
          fix-hdmi-audio = ''
            amixer -c 0 sset IEC958,1 unmute $argv
          '';
        };
      };

      starship = {
        enable = true;
        enableFishIntegration = true;

        # https://starship.rs/config
        settings = {
          line_break.disabled = true;
          time.disabled = false;
          cmd_duration.min_time = 1000;
          status = {
            disabled = false;
            pipestatus = true;
          };
        };
      };

      zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

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

      # Notifications
      mako = {
        enable = true;
        extraConfig = (builtins.readFile (config.scheme inputs.base16-mako));
      };

      # System bar
      waybar = {
        enable = true;
        settings = {
          # TODO: use program paths
          mainBar = {
            backlight = {
              format = "{icon} {percent}%";
              format-icons = [
                ""
                ""
                ""
              ];

              on-scroll-down = "brightnessctl -c backlight set 1%-";
              on-scroll-up = "brightnessctl -c backlight set +1%";
            };

            battery = {
              format = "{icon} {capacity}%";
              format-charging = " {capacity}%";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];

              format-plugged = " {capacity}%";
              states = {
                critical = 15;
                warning = 30;
              };
            };

            clock = {
              format = " {:%H:%M:%S}";
              format-alt = " {:%e %b %Y}";
              interval = 1;
              tooltip-format = "{:%H:%M:%S, %a, %B %d, %Y}";
            };

            cpu = {
              format = " {usage:2}%";
              interval = 5;
              on-click = "alactritty -e htop";
              states = {
                critical = 90;
                warning = 70;
              };
            };

            "custom/files" = {
              format = " ";
              on-click = "exec thunar";
              tooltip = false;
            };

            "custom/firefox" = {
              format = " ";
              on-click = "exec firefox";
              tooltip = false;
            };

            "custom/launcher" = {
              format = " ";
              on-click = "exec wofi -c ~/.config/wofi/config -I";
              tooltip = false;
            };

            "custom/power" = {
              format = "⏻";
              on-click = "exec ${power-module}";
              tooltip = false;
            };

            "custom/terminal" = {
              format = " ";
              on-click = "exec alacritty";
              tooltip = false;
            };

            "custom/weather" = {
              exec = "${weather-module} 'Vancouver,WA'";
              interval = 600;
              return-type = "json";
            };

            disk = {
              format = " {percentage_used}%";
              interval = 5;
              on-click = "alactritty -e 'df -h'";
              path = "/";
              states = {
                critical = 90;
                warning = 70;
              };

              tooltip-format = "Used: {used} ({percentage_used}%)\nFree: {free} ({percentage_free}%)\nTotal: {total}";
            };

            layer = "top";
            memory = {
              format = " {}%";
              interval = 5;
              on-click = "alacritty -e htop";
              states = {
                critical = 90;
                warning = 70;
              };
            };

            modules-center = [
              "clock"
              "custom/weather"
            ];

            modules-left = [
              "custom/launcher"
              "sway/workspaces"
              "sway/mode"
            ];

            modules-right = [
              "network"
              "memory"
              "cpu"
              "disk"
              "pulseaudio"
              "battery"
              "backlight"
              "temperature"
              "tray"
              "custom/power"
            ];

            network = {
              format-disconnected = "⚠ Disconnected";
              format-ethernet = " {ifname}";
              format-wifi = " {signalStrength}%";
              interval = 1;
              on-click = "alacritty -e nmtui";
              tooltip-format = "{ifname}: {ipaddr}\n{essid}\n祝 {bandwidthUpBits:>8}  {bandwidthDownBits:>8}";
            };

            "network#vpn" = {
              format = " {essid} ({signalStrength}%)";
              format-disconnected = "⚠ Disconnected";
              interface = "tun0";
              tooltip-format = "{ifname}: {ipaddr}/{cidr}";
            };

            position = "top";
            pulseaudio = {
              format = "{icon} {volume}%";
              format-bluetooth = "{icon} {volume}%  {format_source}";
              format-bluetooth-muted = " {icon}  {format_source}";
              format-icons = {
                car = "";
                default = [ "" ];
                hands-free = "וֹ";
                headphone = "";
                headset = "  ";
                phone = "";
                portable = "";
              };

              format-muted = "婢 {format_source}";
              format-source = "{volume}% ";
              format-source-muted = "";
              on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
              on-click-right = "pavucontrol";
              scroll-step = 1;
            };

            "sway/mode" = {
              format = "{}";
              tooltip = false;
            };

            "sway/window" = {
              format = "{}";
              max-length = 120;
            };

            "sway/workspaces" = {
              all-outputs = false;
              disable-markup = false;
              disable-scroll = true;
              format = " {icon} ";
            };

            tray = {
              icon-size = 18;
              spacing = 10;
            };
          };
        };

        style = ''
          /*****************/
          /***** Theme *****/
          /*****************/

          @import "${config.scheme inputs.base16-waybar}";

          /**********************/
          /***** Global/Bar *****/
          /**********************/

          * {
            font-family: NotoSansMono Nerd Font;
            font-size: 14px;

            /* Slanted */
            border-radius: 0.3em 0.9em;

            /* None */
            /*border-radius: 0;*/

            outline: none;
            border-color: transparent;
          }

          #waybar {
            background: @base00;
          }

          label {
            padding: 0 0.5em;
            margin: 0.3em;
            color: @base05;
          }

          /************************/
          /***** Left modules *****/
          /************************/

          /* Use button padding instead of label */
          #workspaces label {
            padding: 0;
            margin: 0;
          }

          #workspaces button {
            padding: 0;
            margin: 0.3em 0.2em;
          }

          /* Workspace highlighting */

          /* Plain and translucent by default */
          #workspaces button {
            box-shadow: 0 -0.2em alpha(@base04, 0.5);
            background: alpha(@base04, 0.25);
          }

          /* More opaque when hovered */
          #workspaces :hover {
            box-shadow: 0 -0.2em @base04;
            background: alpha(@base04, 0.5);
          }

          /* Change color when focused */
          #workspaces .focused {
            box-shadow: 0 -0.2em alpha(@base0F, 0.75);
            background: alpha(@base0F, 0.25);
          }

          /* Change color and more opaque when both */
          #workspaces :hover.focused {
            box-shadow: 0 -0.2em @base0F;
            background: alpha(@base0F, 0.5);
          }

          /**************************/
          /***** Center modules *****/
          /**************************/

          /* Center weather icon*/

          #custom-weather {
            margin-left: -0.5em;
            margin-right: 3em;
          }

          /*************************/
          /***** Right modules *****/
          /*************************/

          /* Module backgrounds */
          #network {
            box-shadow: 0 -0.2em @base0F;
            background: alpha(@base0F, 0.25);
          }

          #memory {
            box-shadow: 0 -0.2em @base08;
            background: alpha(@base08, 0.25);
          }

          #cpu {
            box-shadow: 0 -0.2em @base0A;
            background: alpha(@base0A, 0.25);
          }

          #disk {
            box-shadow: 0 -0.2em @base0D;
            background: alpha(@base0D, 0.25);
          }

          #pulseaudio {
            box-shadow: 0 -0.2em @base0C;
            background: alpha(@base0C, 0.25);
          }

          #battery {
            box-shadow: 0 -0.2em @base0B;
            background: alpha(@base0B, 0.25);
          }

          #backlight {
            box-shadow: 0 -0.2em @base06;
            background: alpha(@base06, 0.25);
          }

          #temperature {
            box-shadow: 0 -0.2em @base09;
            background: alpha(@base09, 0.25);
          }

          #tray {
            padding: 0 0.5em;
            margin: 0.3em 0.2em;

            box-shadow: 0 -0.2em @base0E;
            background: alpha(@base0E, 0.25);
          }

          /* Fix tooltip background */
          tooltip, tooltip label {
            background: @base02;
          }
        '';
      };

      bottom = {
        enable = true;

        # https://github.com/ClementTsang/bottom/blob/master/sample_configs/default_config.toml
        settings = {
          flags = {
            mem_as_value = true;
          };
        };
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
      configFile = {
        #################################
        ##### Sway (window manager) #####
        #################################

        sway.source = ./home/sway;
        swaylock.source = ./home/swaylock;

        ################################
        ##### Wofi (notifications) #####
        ################################

        wofi = {
          # Needs to be recursive so that styles below can be written
          recursive = true;
          source = ./home/wofi;
        };

        "wofi/style.css".text = ''
          *{
            font-family: NotoSansMono Nerd Font;
            font-size: 14px;
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

          ${builtins.readFile (config.scheme inputs.base16-wofi)}
        '';

        "wofi/style.widgets.css".text = ''
          *{
            font-family: NotoSansMono Nerd Font;
            font-size: 14px;
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

          ${builtins.readFile (config.scheme inputs.base16-wofi)}
        '';

        ################
        ##### Wrap #####
        ################

        "wrap.yaml" = {
          onChange = ''
            $HOME/.cargo/bin/wrap --alias
          '';

          text = ''
            variables:
              CUTTLEFISH_SSH_PORT: 32085
              CUTTLEFISH_SSH_URL: ssh.sigpanic.com

              DRYWELL_SSH_PORT: 57332
              DRYWELL_SSH_URL: drywell.sigpanic.com

            aliases:
              - alias: drywell
                program: ssh

                keywords:
                  - keys: [--local]
                    values: [192.168.1.200]
                  - keys: [--remote]
                    values: [-p, $DRYWELL_SSH_PORT, $DRYWELL_SSH_URL]

              - alias: cuttlefish
                program: ssh

                arguments:
                  - key: -i
                    value: ~/.ssh/archbook.id_rsa
                    cleared-by: [-i]

                keywords:
                  - keys: [--local]
                    values: [192.168.1.230]
                  - keys: [--remote]
                    values: [-p, $CUTTLEFISH_SSH_PORT, $CUTTLEFISH_SSH_URL]

              # System yadm
              # Clone via: syadm clone -w / <repo>
              - alias: syadm
                program: sudo

                arguments:
                  - key: /etc/yadm/data
                  - key: --yadm-data
                  - key: /etc/yadm/config
                  - key: --yadm-dir
                  - key: yadm
                  - key: GIT_SSH_COMMAND=ssh -i $HOME/.ssh/id_rsa
                  - key: HOME=$HOME

              - alias: a
                program: awk

                keywords:
                  - keys: [--unique, -u]
                    values: ['!a[\$0]++']

              - alias: maintain
                program: sh

                arguments:
                  - key: -c

                keywords:
                  - keys: [--bg]
                    values: ['killall swaybg; swaybg -i ~/.config/sway/wallpapers/spaceman.jpg &']

              - alias: theme
                program: sh

                arguments:
                  - key: -c

                keywords:
                  - keys: [--iterate]
                    values:
                      - |
                        for theme in \$(flavours list | awk -v RS=' ' '!/-light/'); do
                          echo \$theme
                          flavours apply \$theme
                          sleep 1
                        done
                  - keys: [--iterate-random]
                    values:
                      - |
                        for theme in \$(flavours list | awk -v RS=' ' '!/-light/' | sort -R); do
                          echo \$theme
                          flavours apply \$theme
                          sleep 1
                        done
                  - keys: [--apply]
                    values: ['flavours apply \$(cat ~/.local/share/flavours/lastscheme)']
                  - keys: [--show]
                    values:
                      - flavours info "\$(flavours current)" | awk '!a[\$0]++'
          '';
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
      # For debugging themes
      lxappearance-xwayland

      # So that links open in a browser when clicked from other applications
      # (e.g. vscode)
      xdg-utils

      # Misc dev tools
      jq
      go-task
    ];

    services = {
      redshift = {
        enable = true;
        provider = "geoclue2";
        package = pkgs.redshift-wlr;
      };
    };
  };
}
