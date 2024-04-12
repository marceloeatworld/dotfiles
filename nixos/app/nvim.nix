{ pkgs, ... }:
#let
#  fromGitHub = ref: repo:
#    pkgs.vimUtils.buildVimPlugin {
#      pname = "${lib.strings.sanitizeDerivationName repo}";
#      version = ref;
#      src = builtins.fetchGit {
#        url = "https://github.com/${repo}.git";
#        ref = ref;
#      };
#    };
#in
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
plugins = with pkgs.vimPlugins; [
        # bufferline-nvim
        catppuccin-nvim
        # git-blame-nvim
        gruvbox-nvim
        # neodev-nvim
        # neorg
        # null-ls-nvim
        # nvim-colorizer-lua
        # orgmode
        trouble-nvim
        # which-key-nvim
        cmp-buffer
        vim-test
        cmp-cmdline
        cmp-nvim-lsp
        cmp-path
        cmp_luasnip
        # copilot-vim
        gitsigns-nvim
        indent-blankline-nvim
        kanagawa-nvim
        lsp-zero-nvim
        lspkind-nvim
        luasnip
        markdown-preview-nvim
        mini-nvim
        nvim-autopairs
        nvim-cmp
        comment-nvim
        nvim-cursorline
        # nvim-dap
        gruvbox-material
        # nvim-dap-go
        # nvim-dap-ui
        # nvim-jdtls
        nvim-lspconfig
        nvim-tree-lua
        nvim-treesitter-textsubjects
        nvim-treesitter.withAllGrammars
        nvim-web-devicons
        plenary-nvim
        telescope-nvim
        nvim-highlight-colors
        vim-fugitive
        vim-table-mode
        wilder-nvim
        rose-pine
        symbols-outline-nvim
        lush-nvim
        zenbones-nvim
        # vista-vim
        # dropbar-nvim
        # (fromGitHub "HEAD" "Bekaboo/dropbar.nvim")
        # (fromGitHub "HEAD" "MunifTanjim/nui.nvim")
        # (fromGitHub "HEAD" "SmiteshP/nvim-navbuddy")
        # (fromGitHub "HEAD" "SmiteshP/nvim-navic")
        # (fromGitHub "HEAD" "Vonr/align.nvim")
        # (fromGitHub "HEAD" "Wansmer/symbol-usage.nvim")
        # (fromGitHub "HEAD" "akinsho/org-bullets.nvim")
        # (fromGitHub "HEAD" "davidmh/cspell.nvim")
        # (fromGitHub "HEAD" "dccsillag/magma-nvim")
        #(fromGitHub "HEAD" "dgagn/diagflow.nvim")
        # (fromGitHub "HEAD" "github/copilot.vim")
        # (fromGitHub "HEAD" "j-morano/buffer_manager.nvim")
        # (fromGitHub "HEAD" "jmbuhr/otter.nvim")
        # (fromGitHub "HEAD" "luckasRanarison/nvim-devdocs")
        # (fromGitHub "HEAD" "postfen/clipboard-image.nvim")
        #(fromGitHub "HEAD" "projekt0n/github-nvim-theme")
        # (fromGitHub "HEAD" "someone-stole-my-name/yaml-companion.nvim")
        # (fromGitHub "HEAD" "toppair/reach.nvim")
        #(fromGitHub "HEAD" "zbirenbaum/copilot-cmp")
        #(fromGitHub "HEAD" "zbirenbaum/copilot.lua")
        #(fromGitHub "HEAD" "jakewvincent/mkdnflow.nvim")
        #(fromGitHub "HEAD" "stevearc/conform.nvim")
        # (fromGitHub "HEAD" "Wansmer/symbol-usage.nvim")
        #(fromGitHub "HEAD" "stevearc/oil.nvim")
        #(fromGitHub "HEAD" "Mofiqul/vscode.nvim")
        # (fromGitHub "HEAD" "David-Kunz/gen.nvim")
      ];
   
  };
}
