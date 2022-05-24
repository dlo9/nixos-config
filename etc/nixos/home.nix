# Home manager configuration
# - Manual: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
# - Config: https://rycee.gitlab.io/home-manager/options.html

{ config, pkgs, lib, inputs, sysCfg, ... }:

with lib;
with types;

let
  cfg = config.home;
in
{
  imports = [ inputs.base16.homeManagerModule ];

  options.home = {
    enable = mkEnableOption "user home management" // { default = true; };
    enableGui = mkEnableOption "graphical programs" // { default = true; };
  };

  config = mkIf cfg.enable {
    scheme = "${inputs.base16-atelier}/atelier-seaside.yaml";

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

        plugins = with pkgs; with sysCfg.pkgs; [
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

        plugins = with pkgs.vimPlugins; with sysCfg.pkgs; [
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
          set -gx EDITOR vim
          set -gx TZ America/Los_Angeles

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
        settings = {
          window.opacity = 0.9;
          decorations = "full";
          font.normal.family = "DejaVuSansMono Nerd Font Mono";

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
    };

    services = {
      redshift = {
        enable = true;
        provider = "geoclue2";
        package = pkgs.redshift-wlr;
      };
    };
  };
}

