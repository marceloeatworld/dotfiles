# Neovim configuration
{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      # Essential plugins
      vim-sensible
      vim-commentary
      vim-surround
      vim-repeat

      # File navigation
      telescope-nvim
      nvim-tree-lua

      # Syntax and LSP
      nvim-treesitter.withAllGrammars
      nvim-lspconfig

      # Autocomplete
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip

      # UI
      lualine-nvim
      nvim-web-devicons
      catppuccin-nvim

      # Git
      gitsigns-nvim
      vim-fugitive

      # Misc
      which-key-nvim
      indent-blankline-nvim
    ];

    extraPackages = with pkgs; [
      # Language server (Nix only)
      nil  # Nix LSP for editing NixOS configs

      # Formatter (Nix only)
      nixpkgs-fmt

      # Search tools
      ripgrep
      fd
    ];

    extraConfig = ''
      " Basic settings
      set number
      set relativenumber
      set mouse=a
      set clipboard=unnamedplus
      set expandtab
      set tabstop=2
      set shiftwidth=2
      set smartindent
      set termguicolors

      " Theme
      colorscheme catppuccin-mocha

      " Leader key
      let mapleader = " "

      " Basic keymaps
      nnoremap <leader>w :w<CR>
      nnoremap <leader>q :q<CR>
      nnoremap <leader>e :NvimTreeToggle<CR>
      nnoremap <leader>ff :Telescope find_files<CR>
      nnoremap <leader>fg :Telescope live_grep<CR>
      nnoremap <leader>fb :Telescope buffers<CR>

      " LSP configuration (Nix only)
      lua << EOF
      local lspconfig = require('lspconfig')

      -- Nil LSP for Nix
      lspconfig.nil_ls.setup({
        settings = {
          ['nil'] = {
            formatting = {
              command = { "nixpkgs-fmt" },
            },
          },
        },
      })

      -- Keybindings LSP
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {})
      EOF
    '';
  };
}
