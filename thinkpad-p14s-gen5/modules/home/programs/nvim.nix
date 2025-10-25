# Neovim configuration
{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Plugins DISABLED due to build errors in NixOS 25.05
    # catppuccin-nvim and nvim-tree-lua have known build issues
    # You can configure Neovim manually after installation with your preferred plugin manager
    # (lazy.nvim, packer.nvim, vim-plug, etc.)

    # Minimal working plugins only
    plugins = with pkgs.vimPlugins; [
      # Essential plugins that work reliably
      vim-sensible
      vim-commentary
      vim-surround
      vim-repeat
      vim-fugitive  # Git integration
    ];

    extraPackages = with pkgs; [
      # Language server (Nix only)
      nil  # Nix LSP for editing NixOS configs

      # Formatter (Nix only)
      nixpkgs-fmt
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

      " Leader key
      let mapleader = " "

      " Basic keymaps
      nnoremap <leader>w :w<CR>
      nnoremap <leader>q :q<CR>

      " Note: After installation, you can configure Neovim with:
      " - lazy.nvim (recommended): https://github.com/folke/lazy.nvim
      " - Or add working plugins back to this file
    '';
  };
}
