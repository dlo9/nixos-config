{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  home.sessionVariables = {
    EDITOR = "vim";
    FLAKE = "/etc/nixos"; # For nh
  };

  programs.vim = {
    enable = true;

    settings = {
      background = "dark";
      copyindent = true;
      hidden = true;
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      smartcase = true;
      tabstop = 2;
    };

    plugins = with pkgs.vimPlugins;
    with pkgs.dlo9.vimPlugins; [
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

      # Centralize backup/swap/undo files to ~/.vim
      vim-central

      # Autocomplete plugins
      coc-nvim # Base
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

      " Use system clipboard for everything
      "set clipboard=unnamed

      " Use system clipboard for yank and paste
      if $WAYLAND_DIRPLAY != ""
        noremap  y  "+y
        noremap  yy  "+yy
        map  p  "+p
        map  P  "+P
      endif

      " Spelling
      " Leader is `\`, so type `\+a` for spelling help
      vmap <leader>a <Plug>(coc-codeaction-selected)
      nmap <leader>a <Plug>(coc-codeaction-selected)

      " Accept autocomplete item. I haven't needed this before, not sure why I do now
      " Make <CR> to accept selected completion item or notify coc.nvim to format
      " <C-g>u breaks current undo, please make your own choice.
      inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
        \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

      " Navigate completion list with tab
      inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
      inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<C-d>"

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
      "inoremap <S-Tab> <C-d>

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

  home.packages = with pkgs; [
    nodejs # For vim plugins
  ];
}
