# Neovim configuration - Modern setup with LazyVim-style plugins
{ pkgs, pkgs-unstable, config, ... }:

{
  programs.neovim = {
    enable = true;
    package = pkgs-unstable.neovim-unwrapped;  # Latest Neovim from unstable
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Essential plugins managed by Nix (LazyVim-inspired)
    plugins = with pkgs-unstable.vimPlugins; [
      # Plugin manager helpers
      lazy-nvim

      # LazyVim core
      LazyVim

      # Colorscheme - Monokai Pro (matching your setup)
      monokai-pro-nvim

      # UI Enhancements
      noice-nvim           # Command line, messages, and popups
      nui-nvim             # UI component library
      nvim-notify          # Notification manager
      dressing-nvim        # Better UI for inputs and selects

      # Icons and visuals
      nvim-web-devicons
      lualine-nvim         # Statusline
      bufferline-nvim      # Buffer line
      indent-blankline-nvim  # Indent guides
      which-key-nvim       # Keybinding popup

      # File explorer and navigation
      neo-tree-nvim        # File explorer (better than nvim-tree)
      telescope-nvim       # Fuzzy finder
      telescope-fzf-native-nvim
      trouble-nvim         # Diagnostics list

      # Git integration
      gitsigns-nvim        # Git signs in gutter
      lazygit-nvim         # LazyGit integration
      vim-fugitive         # Git commands

      # LSP and completion
      nvim-lspconfig       # LSP configurations
      nvim-cmp             # Completion engine
      cmp-nvim-lsp         # LSP completion source
      cmp-buffer           # Buffer completion
      cmp-path             # Path completion
      cmp-cmdline          # Command line completion
      cmp_luasnip          # Snippet completion

      # Snippets
      luasnip              # Snippet engine
      friendly-snippets    # Collection of snippets

      # Formatting and linting
      conform-nvim         # Format runner
      nvim-lint            # Linter runner

      # Treesitter (syntax highlighting)
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects
      nvim-treesitter-context

      # Code intelligence
      nvim-autopairs       # Auto close brackets
      comment-nvim         # Smart commenting
      nvim-surround        # Surround text objects
      todo-comments-nvim   # Highlight TODO comments
      vim-repeat           # Repeat plugin commands

      # AI assistance
      copilot-lua          # GitHub Copilot
      copilot-cmp          # Copilot completion source

      # Debugging (DAP)
      nvim-dap             # Debug adapter protocol
      nvim-dap-ui          # DAP UI
      nvim-dap-virtual-text

      # Terminal
      toggleterm-nvim      # Better terminal integration

      # Session management
      persistence-nvim     # Session persistence

      # Utilities
      plenary-nvim         # Lua utilities (required by many plugins)
      vim-tmux-navigator   # Tmux navigation
      markdown-preview-nvim  # Markdown preview

      # Mini.nvim suite (Swiss Army knife)
      mini-nvim            # Full mini.nvim suite

      # Navigation enhancements
      flash-nvim           # Jump anywhere in 2-3 keystrokes
      harpoon2             # Quick file navigation for favorites
      oil-nvim             # Edit filesystem like a buffer

      # Git enhancements
      diffview-nvim        # Beautiful git diff viewer
      neogit               # Magit-like git interface

      # Search and replace
      nvim-spectre         # Global search and replace with preview

      # Code folding
      nvim-ufo             # Modern code folding
      promise-async        # Required by nvim-ufo

      # Colorizer
      nvim-colorizer-lua   # Color highlighter

      # Better quickfix
      nvim-bqf             # Better quickfix window
    ];

    extraPackages = with pkgs-unstable; [
      # LSP servers
      nil              # Nix LSP
      lua-language-server
      pyright          # Python
      rust-analyzer    # Rust
      nodePackages.typescript-language-server  # TypeScript/JavaScript
      nodePackages.vscode-langservers-extracted  # HTML/CSS/JSON
      nodePackages.bash-language-server
      gopls            # Go
      clang-tools      # C/C++

      # Formatters
      nixpkgs-fmt      # Nix
      alejandra        # Nix (alternative)
      stylua           # Lua
      black            # Python
      isort            # Python imports
      prettierd        # JavaScript/TypeScript/JSON/HTML/CSS
      shfmt            # Shell

      # Linters
      statix           # Nix linter
      shellcheck       # Shell script linter

      # Tools
      ripgrep          # Required by Telescope
      fd               # Required by Telescope
      lazygit          # Git TUI
      gcc              # Required by Treesitter
      nodejs           # Required by Copilot
      tree-sitter      # Treesitter CLI
    ];

    # Lua configuration directory
    extraLuaConfig = ''
      -- Leader key (must be set before lazy)
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      -- Basic options
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.mouse = "a"
      vim.opt.clipboard = "unnamedplus"
      vim.opt.expandtab = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.smartindent = true
      vim.opt.termguicolors = true
      vim.opt.cursorline = true
      vim.opt.signcolumn = "yes"
      vim.opt.wrap = false
      vim.opt.scrolloff = 8
      vim.opt.sidescrolloff = 8
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.updatetime = 200
      vim.opt.timeoutlen = 300
      vim.opt.undofile = true
      vim.opt.swapfile = false
      vim.opt.splitright = true
      vim.opt.splitbelow = true

      -- Colorscheme - Monokai Pro Ristretto (matching your Hyprland/Waybar)
      require("monokai-pro").setup({
        filter = "ristretto",
        transparent_background = false,
        devicons = true,
      })
      vim.cmd([[colorscheme monokai-pro]])

      -- Lualine setup
      require('lualine').setup({
        options = {
          theme = 'monokai-pro',
          icons_enabled = true,
          component_separators = { left = "", right = ""},
          section_separators = { left = "", right = ""},
        },
      })

      -- Neo-tree (File explorer)
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = { enabled = true },
          hijack_netrw_behavior = "open_current",
        },
      })

      -- Telescope (Fuzzy finder)
      local telescope = require('telescope')
      telescope.setup({
        defaults = {
          prompt_prefix = "   ",
          selection_caret = " ",
          file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/" },
        },
      })
      telescope.load_extension('fzf')

      -- Which-key (Keybinding popup)
      local wk = require("which-key")
      wk.setup({})

      -- LSP keymaps (LazyVim-style)
      wk.add({
        -- File operations
        { "<leader>f", group = "file" },
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },

        -- Explorer
        { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer" },

        -- Buffer operations
        { "<leader>b", group = "buffer" },
        { "<leader>bd", "<cmd>bd<cr>", desc = "Delete Buffer" },
        { "<leader>bn", "<cmd>bnext<cr>", desc = "Next Buffer" },
        { "<leader>bp", "<cmd>bprevious<cr>", desc = "Previous Buffer" },

        -- Git operations
        { "<leader>g", group = "git" },
        { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
        { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit" },
        { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff View" },
        { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "File History" },
        { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Branches" },
        { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Commits" },

        -- Search operations
        { "<leader>s", group = "search" },
        { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
        { "<leader>sr", "<cmd>lua require('spectre').open()<cr>", desc = "Replace (Spectre)" },
        { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help" },

        -- Code operations
        { "<leader>c", group = "code" },
        { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action" },
        { "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
        { "<leader>cf", vim.lsp.buf.format, desc = "Format" },

        -- Diagnostics
        { "<leader>x", group = "diagnostics" },
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
        { "<leader>xd", vim.diagnostic.open_float, desc = "Line Diagnostics" },

        -- Quick actions
        { "<leader>w", "<cmd>w<cr>", desc = "Save" },
        { "<leader>q", "<cmd>q<cr>", desc = "Quit" },

        -- Oil (filesystem editor)
        { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },

        -- Flash (jump navigation)
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },

        -- Harpoon (file marks)
        { "<leader>h", group = "harpoon" },
        { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Add file" },
        { "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Toggle menu" },
        { "<leader>h1", function() require("harpoon"):list():select(1) end, desc = "File 1" },
        { "<leader>h2", function() require("harpoon"):list():select(2) end, desc = "File 2" },
        { "<leader>h3", function() require("harpoon"):list():select(3) end, desc = "File 3" },
        { "<leader>h4", function() require("harpoon"):list():select(4) end, desc = "File 4" },

        -- UFO (code folding)
        { "zR", function() require('ufo').openAllFolds() end, desc = "Open all folds" },
        { "zM", function() require('ufo').closeAllFolds() end, desc = "Close all folds" },
      })

      -- LSP configuration
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Configure LSP servers
      local servers = { 'nil_ls', 'lua_ls', 'pyright', 'rust_analyzer', 'tsserver', 'gopls', 'clangd' }
      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup({
          capabilities = capabilities,
        })
      end

      -- Completion setup
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'copilot' },
          { name = 'buffer' },
          { name = 'path' },
        }),
      })

      -- Treesitter setup
      require('nvim-treesitter.configs').setup({
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = { enable = true },
      })

      -- Auto pairs
      require('nvim-autopairs').setup({})

      -- Comment.nvim
      require('Comment').setup({})

      -- Gitsigns
      require('gitsigns').setup({
        signs = {
          add = { text = '│' },
          change = { text = '│' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
      })

      -- GitHub Copilot
      require("copilot").setup({
        suggestion = { enabled = true, auto_trigger = true },
        panel = { enabled = true },
      })

      -- Noice (beautiful command line)
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
        },
      })

      -- Indent blankline
      require("ibl").setup({
        indent = { char = "│" },
        scope = { enabled = false },
      })

      -- Todo comments
      require("todo-comments").setup({})

      -- Persistence (session management)
      require("persistence").setup({})

      -- Flash.nvim (Jump navigation)
      require("flash").setup({})

      -- Harpoon (File marks)
      local harpoon = require("harpoon")
      harpoon:setup({})

      -- Oil.nvim (Edit filesystem like buffer)
      require("oil").setup({
        columns = { "icon" },
        view_options = {
          show_hidden = true,
        },
      })

      -- Diffview (Git diff viewer)
      require("diffview").setup({})

      -- Neogit (Git interface)
      require("neogit").setup({})

      -- Nvim-spectre (Search and replace)
      require("spectre").setup({})

      -- UFO (Code folding)
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      require('ufo').setup({
        provider_selector = function()
          return {'treesitter', 'indent'}
        end
      })

      -- Colorizer (Highlight colors)
      require('colorizer').setup({})

      -- Better quickfix
      require('bqf').setup({})

      -- Mini.nvim modules
      require('mini.ai').setup({})        -- Better text objects
      require('mini.bufremove').setup({}) -- Better buffer remove
      require('mini.surround').setup({})  -- Surround operations

      -- Basic keymaps (Vim-style)
      local keymap = vim.keymap

      -- Better window navigation
      keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
      keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
      keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
      keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

      -- Resize windows
      keymap.set("n", "<C-Up>", ":resize -2<CR>", { desc = "Decrease window height" })
      keymap.set("n", "<C-Down>", ":resize +2<CR>", { desc = "Increase window height" })
      keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
      keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

      -- Better paste
      keymap.set("v", "p", '"_dP', { desc = "Paste without yanking" })

      -- Clear search highlight
      keymap.set("n", "<Esc>", ":noh<CR>", { desc = "Clear highlights" })

      -- LSP keymaps
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local opts = { buffer = args.buf }
          keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        end,
      })
    '';
  };
}
