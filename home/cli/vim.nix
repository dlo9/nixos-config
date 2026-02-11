{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  home.sessionVariables = {
    EDITOR = "nvim";
    NH_FLAKE = "/etc/nixos"; # For nh
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      # Statusline
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require('lualine').setup({
            options = {
              icons_enabled = true,
              theme = 'auto',
            },
            tabline = {
              lualine_a = {'buffers'},
              lualine_z = {'tabs'},
            },
          })
        '';
      }

      # Auto-detect indentation
      {
        plugin = guess-indent-nvim;
        type = "lua";
        config = ''
          require('guess-indent').setup({})
        '';
      }

      # Autocomplete
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          local cmp = require('cmp')
          cmp.setup({
            snippet = {
              expand = function(args)
                vim.snippet.expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ['<Tab>'] = cmp.mapping.select_next_item(),
              ['<S-Tab>'] = cmp.mapping.select_prev_item(),
              ['<CR>'] = cmp.mapping.confirm({ select = false }),
              ['<C-Space>'] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
            }, {
              { name = 'buffer' },
              { name = 'path' },
            }),
          })
        '';
      }
      cmp-nvim-lsp
      cmp-buffer
      cmp-path

      # LSP (nvim-lspconfig provides lsp/*.lua config files on runtimepath)
      nvim-lspconfig

      # Git signs in the gutter
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = ''
          require('gitsigns').setup()
        '';
      }

      # Web devicons (for lualine and other plugins)
      nvim-web-devicons
    ];

    extraLuaConfig = ''
      -- LSP: global defaults
      vim.lsp.config('*', {
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
        root_markers = { '.git' },
      })

      -- LSP: enable servers (configs provided by nvim-lspconfig lsp/*.lua files)
      vim.lsp.enable({
        'rust_analyzer',
        'gopls',
        'yamlls',
        'bashls',
        'dockerls',
        'lua_ls',
        'biome',
      })

      -- LSP: keybindings on attach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, opts)
          vim.keymap.set('v', '<leader>a', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        end,
      })

      -- General
      vim.opt.history = 80
      vim.opt.autoread = true
      vim.opt.background = 'dark'
      vim.opt.mouse = ""  -- Disable mouse (nvim enables by default), allows terminal link clicking

      -- Line numbers
      vim.opt.number = true

      -- System clipboard for yank/paste in Wayland
      if vim.env.WAYLAND_DISPLAY and vim.env.WAYLAND_DISPLAY ~= "" then
        vim.opt.clipboard = 'unnamedplus'
      end

      -- Spelling
      vim.opt.spell = true
      vim.opt.spelllang = { 'en_us' }

      -- UI
      vim.opt.scrolloff = 7
      vim.opt.wildmenu = true
      vim.opt.ruler = true
      vim.opt.hidden = true
      vim.opt.backspace = { 'indent', 'eol', 'start' }
      vim.opt.whichwrap:append('<,>,h,l')
      vim.opt.lazyredraw = true
      vim.opt.magic = true
      vim.opt.showmatch = true
      vim.opt.errorbells = false
      vim.opt.visualbell = false
      vim.opt.timeoutlen = 500

      -- Search
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.hlsearch = true
      vim.opt.incsearch = true

      -- File encoding
      vim.opt.encoding = 'utf-8'
      vim.opt.fileformats = { 'unix', 'dos', 'mac' }

      -- Tabs and indentation (fallback; guess-indent overrides per file)
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.softtabstop = 2
      vim.opt.tabstop = 2
      vim.opt.smarttab = true
      vim.opt.copyindent = true

      -- Line wrapping
      vim.opt.linebreak = true

      -- Persistent undo
      vim.opt.undofile = true

      -- Strip trailing whitespace on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*',
        callback = function()
          local save = vim.fn.winsaveview()
          vim.cmd([[%s/\s\+$//e]])
          vim.fn.winrestview(save)
        end,
      })

      -- Remember last cursor position
      vim.api.nvim_create_autocmd('BufReadPost', {
        pattern = '*',
        callback = function()
          local mark = vim.api.nvim_buf_get_mark(0, '"')
          local line_count = vim.api.nvim_buf_line_count(0)
          if mark[1] > 0 and mark[1] <= line_count then
            vim.api.nvim_win_set_cursor(0, mark)
          end
        end,
      })

      -- Filetype-specific indentation
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'yaml',
        callback = function()
          vim.opt_local.tabstop = 2
          vim.opt_local.expandtab = true
          vim.opt_local.shiftwidth = 2
          vim.opt_local.softtabstop = 2
        end,
      })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'python',
        callback = function()
          vim.opt_local.tabstop = 4
          vim.opt_local.expandtab = true
          vim.opt_local.shiftwidth = 4
          vim.opt_local.softtabstop = 4
        end,
      })

      -- Keymaps: treat long lines as break lines
      vim.keymap.set("", 'j', 'gj')
      vim.keymap.set("", 'k', 'gk')

      -- Clear search highlight with <leader><CR>
      vim.keymap.set("", '<leader><CR>', ':noh<CR>', { silent = true })

      -- Faster window navigation
      vim.keymap.set("", '<C-j>', '<C-W>j')
      vim.keymap.set("", '<C-k>', '<C-W>k')
      vim.keymap.set("", '<C-h>', '<C-W>h')
      vim.keymap.set("", '<C-l>', '<C-W>l')

      -- Close all buffers
      vim.keymap.set("", '<leader>ba', ':1,1000 bd!<CR>')

      -- Tab management
      vim.keymap.set("", '<leader>tn', ':tabnew<CR>')
      vim.keymap.set("", '<leader>to', ':tabonly<CR>')
      vim.keymap.set("", '<leader>tc', ':tabclose<CR>')
      vim.keymap.set("", '<leader>tm', ':tabmove')
    '';
  };

  home.packages = with pkgs; [
    # LSP servers
    rust-analyzer
    gopls
    yaml-language-server
    nodePackages.bash-language-server
    dockerfile-language-server
    lua-language-server
    biome
  ];
}
