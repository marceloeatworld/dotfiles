# Neovim configuration - Beginner-friendly LazyVim-style setup
# Optimized for polyglot development with intelligent auto-completion
{ pkgs, pkgs-unstable, config, ... }:

{
  programs.neovim = {
    enable = true;
    package = pkgs-unstable.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs-unstable.vimPlugins; [
      # ══════════════════════════════════════════════════════════════════
      # CORE & UI
      # ══════════════════════════════════════════════════════════════════
      plenary-nvim                 # Lua utilities (required by many plugins)
      lualine-nvim                 # Status line

      # Colorscheme
      monokai-pro-nvim

      # Dashboard - Welcome screen with shortcuts
      alpha-nvim

      # UI Components
      noice-nvim                   # Beautiful command line & messages
      nui-nvim                     # UI component library
      nvim-notify                  # Notification manager
      dressing-nvim                # Better UI for inputs/selects
      nvim-web-devicons            # File icons

      # Status line & Buffer line
      bufferline-nvim              # Buffer tabs at top
      indent-blankline-nvim        # Indent guides

      # Help & Navigation
      which-key-nvim               # Keybinding popup (shows available keys)

      # ══════════════════════════════════════════════════════════════════
      # FILE NAVIGATION
      # ══════════════════════════════════════════════════════════════════
      neo-tree-nvim                # File explorer sidebar
      telescope-nvim               # Fuzzy finder (files, grep, etc.)
      telescope-fzf-native-nvim    # Faster telescope search
      oil-nvim                     # Edit filesystem like a buffer
      flash-nvim                   # Jump anywhere in 2-3 keystrokes
      harpoon2                     # Quick marks for favorite files

      # ══════════════════════════════════════════════════════════════════
      # GIT INTEGRATION
      # ══════════════════════════════════════════════════════════════════
      gitsigns-nvim                # Git signs in gutter (+/-/~)
      lazygit-nvim                 # LazyGit integration
      vim-fugitive                 # Git commands
      diffview-nvim                # Beautiful git diff viewer
      neogit                       # Magit-like git interface

      # ══════════════════════════════════════════════════════════════════
      # LSP & COMPLETION (Intelligent Auto-completion)
      # ══════════════════════════════════════════════════════════════════
      nvim-lspconfig               # LSP configurations
      lsp_signature-nvim           # Function signature help while typing
      trouble-nvim                 # Diagnostics list

      # Completion engine
      nvim-cmp                     # Main completion engine
      cmp-nvim-lsp                 # LSP completion source
      cmp-nvim-lsp-signature-help  # Signature help in completion
      cmp-buffer                   # Buffer words completion
      cmp-path                     # File path completion
      cmp-cmdline                  # Command line completion
      cmp_luasnip                  # Snippet completion
      lspkind-nvim                 # VSCode-like icons in completion

      # Snippets
      luasnip                      # Snippet engine
      friendly-snippets            # Collection of useful snippets

      # Formatting & Linting
      conform-nvim                 # Format runner (format on save)
      nvim-lint                    # Linter runner

      # ══════════════════════════════════════════════════════════════════
      # TREESITTER (Syntax Highlighting & Code Understanding)
      # ══════════════════════════════════════════════════════════════════
      nvim-treesitter.withAllGrammars
      nvim-treesitter-context      # Shows current function/class at top

      # ══════════════════════════════════════════════════════════════════
      # CODE INTELLIGENCE
      # ══════════════════════════════════════════════════════════════════
      nvim-autopairs               # Auto close brackets (){}[]
      comment-nvim                 # Smart commenting (gc)
      nvim-surround                # Surround text objects
      todo-comments-nvim           # Highlight TODO/FIXME/etc.
      vim-repeat                   # Repeat plugin commands with .
      vim-illuminate               # Highlight word under cursor
      nvim-hlslens                 # Better search highlighting with count

      # Code folding
      nvim-ufo                     # Modern code folding
      promise-async                # Required by nvim-ufo

      # ══════════════════════════════════════════════════════════════════
      # AI ASSISTANCE
      # ══════════════════════════════════════════════════════════════════
      copilot-lua                  # GitHub Copilot
      copilot-cmp                  # Copilot in completion menu

      # ══════════════════════════════════════════════════════════════════
      # DEBUGGING
      # ══════════════════════════════════════════════════════════════════
      nvim-dap                     # Debug adapter protocol
      nvim-dap-ui                  # Debug UI
      nvim-dap-virtual-text        # Show variable values inline

      # ══════════════════════════════════════════════════════════════════
      # UTILITIES
      # ══════════════════════════════════════════════════════════════════
      toggleterm-nvim              # Better terminal integration
      persistence-nvim             # Session persistence
      nvim-spectre                 # Search and replace across files
      nvim-colorizer-lua           # Show colors inline (#ff0000)
      nvim-bqf                     # Better quickfix window
      nvim-scrollbar               # Scrollbar with diagnostics
      vim-tmux-navigator           # Tmux navigation
      markdown-preview-nvim        # Markdown preview

      # Mini.nvim suite
      mini-nvim                    # Swiss army knife of small plugins
    ];

    extraPackages = with pkgs-unstable; [
      # ══════════════════════════════════════════════════════════════════
      # LSP SERVERS
      # ══════════════════════════════════════════════════════════════════
      # Nix
      nil                          # Nix LSP

      # Lua
      lua-language-server

      # Python
      pyright
      ruff                         # Fast Python linter/formatter

      # Rust
      rust-analyzer

      # JavaScript/TypeScript
      nodePackages.typescript-language-server

      # Web (HTML/CSS/JSON)
      nodePackages.vscode-langservers-extracted

      # Shell
      nodePackages.bash-language-server

      # Go
      gopls

      # C/C++
      clang-tools

      # YAML
      yaml-language-server

      # Markdown
      marksman

      # ══════════════════════════════════════════════════════════════════
      # FORMATTERS
      # ══════════════════════════════════════════════════════════════════
      nixpkgs-fmt                  # Nix formatter
      alejandra                    # Nix formatter (alternative)
      stylua                       # Lua formatter
      black                        # Python formatter
      isort                        # Python import sorter
      prettierd                    # JS/TS/HTML/CSS/JSON/MD formatter
      shfmt                        # Shell formatter
      rustfmt                      # Rust formatter

      # ══════════════════════════════════════════════════════════════════
      # LINTERS
      # ══════════════════════════════════════════════════════════════════
      statix                       # Nix linter
      deadnix                      # Find dead Nix code
      shellcheck                   # Shell linter
      eslint_d                     # Fast JS/TS linter

      # ══════════════════════════════════════════════════════════════════
      # TOOLS
      # ══════════════════════════════════════════════════════════════════
      ripgrep                      # Fast grep (required by Telescope)
      fd                           # Fast find (required by Telescope)
      lazygit                      # Git TUI
      gcc                          # Required by Treesitter
      nodejs                       # Required by Copilot
      tree-sitter                  # Treesitter CLI
    ];

    extraLuaConfig = ''
      -- ════════════════════════════════════════════════════════════════════
      -- LEADER KEY (must be set before lazy)
      -- ════════════════════════════════════════════════════════════════════
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      -- ════════════════════════════════════════════════════════════════════
      -- VIM OPTIONS
      -- ════════════════════════════════════════════════════════════════════
      local opt = vim.opt

      -- Line numbers
      opt.number = true              -- Show line numbers
      opt.relativenumber = true      -- Relative line numbers (easier jumps)

      -- Tabs & Indentation
      opt.tabstop = 2                -- 2 spaces for tab
      opt.shiftwidth = 2             -- 2 spaces for indent
      opt.expandtab = true           -- Use spaces instead of tabs
      opt.smartindent = true         -- Auto indent new lines

      -- Search
      opt.ignorecase = true          -- Ignore case when searching
      opt.smartcase = true           -- Unless uppercase is used
      opt.hlsearch = true            -- Highlight search results

      -- Appearance
      opt.termguicolors = true       -- True color support
      opt.cursorline = true          -- Highlight current line
      opt.signcolumn = "yes"         -- Always show sign column
      opt.colorcolumn = "100"        -- Show column guide at 100 chars

      -- Behavior
      opt.mouse = "a"                -- Enable mouse support
      opt.clipboard = "unnamedplus"  -- Use system clipboard
      opt.wrap = false               -- Don't wrap lines
      opt.scrolloff = 8              -- Keep 8 lines above/below cursor
      opt.sidescrolloff = 8          -- Keep 8 columns left/right of cursor
      opt.splitright = true          -- Open vertical splits to the right
      opt.splitbelow = true          -- Open horizontal splits below

      -- Performance
      opt.updatetime = 200           -- Faster completion
      opt.timeoutlen = 400           -- Time to wait for mapping (for which-key)

      -- Persistence
      opt.undofile = true            -- Persistent undo
      opt.swapfile = false           -- No swap files

      -- Folding (with nvim-ufo)
      opt.foldcolumn = "1"
      opt.foldlevel = 99
      opt.foldlevelstart = 99
      opt.foldenable = true

      -- Disable deprecation warnings
      vim.g.deprecation_warnings = false

      -- ════════════════════════════════════════════════════════════════════
      -- COLORSCHEME
      -- ════════════════════════════════════════════════════════════════════
      require("monokai-pro").setup({
        filter = "ristretto",
        transparent_background = false,
        devicons = true,
        styles = {
          comment = { italic = true },
          keyword = { italic = false },
        },
        background_clear = { "toggleterm", "telescope", "which-key", "neo-tree" },
      })
      vim.cmd([[colorscheme monokai-pro]])

      -- ════════════════════════════════════════════════════════════════════
      -- ALPHA (Dashboard) - Must be before lazy.nvim
      -- ════════════════════════════════════════════════════════════════════
      local alpha_ok, alpha = pcall(require, "alpha")
      if alpha_ok then
        local dashboard = require("alpha.themes.dashboard")

        dashboard.section.header.val = {
          [[                                                                            ]],
          [[  ██████╗██╗   ██╗████████╗███████╗██████╗  █████╗ ████████╗ █████╗         ]],
          [[ ██╔════╝██║   ██║╚══██╔══╝██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗        ]],
          [[ ██║     ██║   ██║   ██║   █████╗  ██║  ██║███████║   ██║   ███████║        ]],
          [[ ██║     ██║   ██║   ██║   ██╔══╝  ██║  ██║██╔══██║   ██║   ██╔══██║        ]],
          [[ ╚██████╗╚██████╔╝   ██║   ███████╗██████╔╝██║  ██║   ██║   ██║  ██║        ]],
          [[  ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝        ]],
          [[                                                                            ]],
        }

        dashboard.section.buttons.val = {
          dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
          dashboard.button("r", "  Recent files", ":Telescope oldfiles <CR>"),
          dashboard.button("g", "  Find text", ":Telescope live_grep <CR>"),
          dashboard.button("e", "  File explorer", ":Neotree toggle <CR>"),
          dashboard.button("c", "  Configuration", ":e $MYVIMRC <CR>"),
          dashboard.button("s", "  Restore session", ":lua require('persistence').load() <CR>"),
          dashboard.button("q", "  Quit", ":qa <CR>"),
        }

        dashboard.section.footer.val = {
          "",
          "  Quick tips: <Space> = Leader | <Space>? = Show all keybinds",
          "  <Space>e = Explorer | <Space>ff = Find file | <Space>fg = Search",
        }

        alpha.setup(dashboard.config)
      end

      -- ════════════════════════════════════════════════════════════════════
      -- LUALINE (Status Line)
      -- ════════════════════════════════════════════════════════════════════
      require('lualine').setup({
        options = {
          theme = 'monokai-pro',
          icons_enabled = true,
          component_separators = { left = "", right = ""},
          section_separators = { left = "", right = ""},
          globalstatus = true,
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = {
            { -- Show active LSP
              function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients > 0 then
                  return " " .. clients[1].name
                end
                return ""
              end,
            },
            'encoding',
            'filetype',
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
      })

      -- ════════════════════════════════════════════════════════════════════
      -- BUFFERLINE (Buffer Tabs)
      -- ════════════════════════════════════════════════════════════════════
      require("bufferline").setup({
        options = {
          mode = "buffers",
          numbers = "ordinal",
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,
          show_buffer_close_icons = true,
          show_close_icon = false,
          separator_style = "thin",
          offsets = {
            { filetype = "neo-tree", text = "File Explorer", text_align = "center" },
          },
        },
      })

      -- ════════════════════════════════════════════════════════════════════
      -- WHICH-KEY (Keybinding Help)
      -- ════════════════════════════════════════════════════════════════════
      local wk = require("which-key")
      wk.setup({
        preset = "modern",
        delay = 300,  -- Show popup after 300ms
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "+",
        },
      })

      -- ════════════════════════════════════════════════════════════════════
      -- NEO-TREE (File Explorer)
      -- ════════════════════════════════════════════════════════════════════
      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        filesystem = {
          follow_current_file = { enabled = true },
          hijack_netrw_behavior = "open_current",
          use_libuv_file_watcher = true,
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
        window = {
          width = 35,
          mappings = {
            ["<space>"] = "none",  -- Don't conflict with leader
          },
        },
      })

      -- ════════════════════════════════════════════════════════════════════
      -- TELESCOPE (Fuzzy Finder)
      -- ════════════════════════════════════════════════════════════════════
      local telescope = require('telescope')
      local actions = require('telescope.actions')

      telescope.setup({
        defaults = {
          prompt_prefix = "   ",
          selection_caret = " ",
          path_display = { "truncate" },
          file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/", "__pycache__" },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<Esc>"] = actions.close,
            },
          },
          layout_config = {
            horizontal = { preview_width = 0.5 },
          },
        },
      })
      telescope.load_extension('fzf')

      -- ════════════════════════════════════════════════════════════════════
      -- LSP CONFIGURATION
      -- ════════════════════════════════════════════════════════════════════
      -- Note: lspconfig deprecation warning can be ignored until v3.0.0
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●",
          spacing = 4,
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      -- Diagnostic signs
      local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- LSP servers configuration
      local servers = {
        nil_ls = {},  -- Nix
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              diagnostics = { globals = { 'vim' } },
              workspace = { library = vim.api.nvim_get_runtime_file("", true) },
              telemetry = { enable = false },
            },
          },
        },
        pyright = {},
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = { command = "clippy" },
            },
          },
        },
        ts_ls = {},
        gopls = {},
        clangd = {},
        yamlls = {},
        marksman = {},
        html = {},
        cssls = {},
        jsonls = {},
        bashls = {},
      }

      for server, config in pairs(servers) do
        config.capabilities = capabilities
        lspconfig[server].setup(config)
      end

      -- LSP Signature (show function params while typing)
      require("lsp_signature").setup({
        bind = true,
        hint_enable = true,
        hint_prefix = "󰏪 ",
        handler_opts = { border = "rounded" },
        floating_window = true,
        floating_window_above_cur_line = true,
      })

      -- ════════════════════════════════════════════════════════════════════
      -- NVIM-CMP (Auto-completion)
      -- ════════════════════════════════════════════════════════════════════
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      local lspkind = require('lspkind')

      -- Load snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol_text',
            maxwidth = 50,
            ellipsis_char = '...',
            symbol_map = { Copilot = "" },
            before = function(entry, vim_item)
              vim_item.menu = ({
                nvim_lsp = "[LSP]",
                luasnip = "[Snippet]",
                copilot = "[AI]",
                buffer = "[Buffer]",
                path = "[Path]",
              })[entry.source.name]
              return vim_item
            end,
          }),
        },
        mapping = cmp.mapping.preset.insert({
          -- Navigation
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-j>'] = cmp.mapping.select_next_item(),
          ['<C-k>'] = cmp.mapping.select_prev_item(),

          -- Trigger & Confirm
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),

          -- Tab completion
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),

          -- Escape handling
          ['<Esc>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.close()
            end
            fallback()
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp', priority = 1000 },
          { name = 'copilot', priority = 900 },
          { name = 'luasnip', priority = 750 },
          { name = 'nvim_lsp_signature_help', priority = 700 },
          { name = 'buffer', priority = 500, keyword_length = 3 },
          { name = 'path', priority = 250 },
        }),
        experimental = {
          ghost_text = true,  -- Show preview of completion
        },
      })

      -- Cmdline completion
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' },
          { name = 'cmdline' },
        }),
      })

      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = 'buffer' } },
      })

      -- ════════════════════════════════════════════════════════════════════
      -- CONFORM (Formatting)
      -- ════════════════════════════════════════════════════════════════════
      require("conform").setup({
        formatters_by_ft = {
          nix = { "nixpkgs_fmt" },
          lua = { "stylua" },
          python = { "isort", "black" },
          javascript = { "prettierd" },
          typescript = { "prettierd" },
          typescriptreact = { "prettierd" },
          javascriptreact = { "prettierd" },
          json = { "prettierd" },
          html = { "prettierd" },
          css = { "prettierd" },
          markdown = { "prettierd" },
          yaml = { "prettierd" },
          sh = { "shfmt" },
          bash = { "shfmt" },
          rust = { "rustfmt" },
          go = { "gofmt" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })

      -- ════════════════════════════════════════════════════════════════════
      -- NVIM-LINT (Linting)
      -- ════════════════════════════════════════════════════════════════════
      require("lint").linters_by_ft = {
        nix = { "statix", "deadnix" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })

      -- ════════════════════════════════════════════════════════════════════
      -- TREESITTER (Neovim 0.11+ native configuration)
      -- ════════════════════════════════════════════════════════════════════
      -- Treesitter is now configured natively via nvim-treesitter.withAllGrammars
      -- Highlight and indent are enabled by default with grammars installed
      vim.treesitter.language.register('bash', 'zsh')

      -- Enable treesitter-based folding
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

      -- Treesitter context (shows function name at top)
      require("treesitter-context").setup({
        enable = true,
        max_lines = 3,
      })

      -- ════════════════════════════════════════════════════════════════════
      -- GIT INTEGRATION
      -- ════════════════════════════════════════════════════════════════════
      require('gitsigns').setup({
        signs = {
          add = { text = '│' },
          change = { text = '│' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        current_line_blame = false,  -- Toggle with <leader>gb
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = "Next git hunk" })

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = "Previous git hunk" })
        end,
      })

      require("neogit").setup({})
      require("diffview").setup({})

      -- ════════════════════════════════════════════════════════════════════
      -- CODE INTELLIGENCE PLUGINS
      -- ════════════════════════════════════════════════════════════════════
      require('nvim-autopairs').setup({})
      require('Comment').setup({})
      require("todo-comments").setup({})
      require("nvim-surround").setup({})

      -- Illuminate (highlight word under cursor)
      require("illuminate").configure({
        delay = 200,
        large_file_cutoff = 2000,
      })

      -- HLSlens (better search)
      require('hlslens').setup({})

      -- UFO (Code folding)
      require('ufo').setup({
        provider_selector = function()
          return { 'treesitter', 'indent' }
        end,
      })

      -- ════════════════════════════════════════════════════════════════════
      -- UI PLUGINS
      -- ════════════════════════════════════════════════════════════════════
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
          lsp_doc_border = true,
        },
      })

      require("ibl").setup({
        indent = { char = "│" },
        scope = { enabled = true, show_start = false, show_end = false },
      })

      require('colorizer').setup({})

      require("scrollbar").setup({
        handle = { color = "#5c5c5c" },
        marks = {
          Search = { color = "#ff9e64" },
          Error = { color = "#db4b4b" },
          Warn = { color = "#e0af68" },
          Info = { color = "#0db9d7" },
          Hint = { color = "#1abc9c" },
          Misc = { color = "#9d7cd8" },
        },
      })

      require('notify').setup({
        background_colour = "#000000",
        timeout = 3000,
      })

      -- ════════════════════════════════════════════════════════════════════
      -- OTHER PLUGINS
      -- ════════════════════════════════════════════════════════════════════
      require("flash").setup({})
      require("harpoon"):setup({})
      require("oil").setup({
        columns = { "icon" },
        view_options = { show_hidden = true },
      })
      require("spectre").setup({})
      require('bqf').setup({})
      require("persistence").setup({})
      require("trouble").setup({})

      require("toggleterm").setup({
        open_mapping = [[<C-\>]],
        direction = "float",
        float_opts = { border = "rounded" },
      })

      -- GitHub Copilot
      require("copilot").setup({
        suggestion = { enabled = true, auto_trigger = true },
        panel = { enabled = true },
      })

      -- Mini.nvim modules
      require('mini.ai').setup({})
      require('mini.bufremove').setup({})
      require('mini.surround').setup({})

      -- ════════════════════════════════════════════════════════════════════
      -- KEYMAPS
      -- ════════════════════════════════════════════════════════════════════
      local keymap = vim.keymap.set

      -- ─────────────────────────────────────────────────────────────
      -- Basic keymaps
      -- ─────────────────────────────────────────────────────────────
      keymap("n", "<Esc>", "<cmd>noh<CR><Esc>", { desc = "Clear search highlight" })
      keymap("i", "jk", "<Esc>", { desc = "Exit insert mode" })
      keymap("i", "kj", "<Esc>", { desc = "Exit insert mode (alt)" })

      -- ─────────────────────────────────────────────────────────────
      -- BEGINNER-FRIENDLY KEYMAPS
      -- These provide familiar shortcuts for those coming from other editors
      -- ─────────────────────────────────────────────────────────────
      -- Save with Ctrl+S (works in all modes)
      keymap("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
      keymap("i", "<C-s>", "<Esc><cmd>w<CR>a", { desc = "Save file" })
      keymap("v", "<C-s>", "<Esc><cmd>w<CR>", { desc = "Save file" })

      -- Undo/Redo with Ctrl+Z and Ctrl+Y
      keymap("n", "<C-z>", "u", { desc = "Undo" })
      keymap("i", "<C-z>", "<Esc>ua", { desc = "Undo" })
      keymap("n", "<C-y>", "<C-r>", { desc = "Redo" })
      keymap("i", "<C-y>", "<Esc><C-r>a", { desc = "Redo" })

      -- Select all with Ctrl+A
      keymap("n", "<C-a>", "ggVG", { desc = "Select all" })

      -- Copy/Cut/Paste with Ctrl (uses system clipboard)
      keymap("v", "<C-c>", '"+y', { desc = "Copy to clipboard" })
      keymap("v", "<C-x>", '"+d', { desc = "Cut to clipboard" })
      keymap("n", "<C-v>", '"+p', { desc = "Paste from clipboard" })
      keymap("i", "<C-v>", '<Esc>"+pa', { desc = "Paste from clipboard" })

      -- Duplicate line with Ctrl+D
      keymap("n", "<C-d>", "yyp", { desc = "Duplicate line" })
      keymap("i", "<C-d>", "<Esc>yypa", { desc = "Duplicate line" })

      -- Delete line with Ctrl+Shift+K (like VS Code)
      keymap("n", "<C-S-k>", "dd", { desc = "Delete line" })
      keymap("i", "<C-S-k>", "<Esc>dda", { desc = "Delete line" })

      -- Find with Ctrl+F (search in file)
      keymap("n", "<C-f>", "/", { desc = "Search in file" })

      -- Go to line with Ctrl+G
      keymap("n", "<C-g>", ":", { desc = "Go to line (type number)" })

      -- Close buffer with Ctrl+W
      keymap("n", "<C-w>q", "<cmd>lua require('mini.bufremove').delete(0, false)<CR>", { desc = "Close buffer" })

      -- New file
      keymap("n", "<C-n>", "<cmd>enew<CR>", { desc = "New file" })

      -- Better window navigation
      keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
      keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
      keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
      keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

      -- Resize windows
      keymap("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
      keymap("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
      keymap("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
      keymap("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

      -- Move lines
      keymap("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
      keymap("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
      keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
      keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

      -- Better indenting
      keymap("v", "<", "<gv", { desc = "Indent left" })
      keymap("v", ">", ">gv", { desc = "Indent right" })

      -- Better paste
      keymap("v", "p", '"_dP', { desc = "Paste without yanking" })

      -- Buffer navigation with Alt+number
      keymap("n", "<A-1>", "<cmd>BufferLineGoToBuffer 1<CR>", { desc = "Go to buffer 1" })
      keymap("n", "<A-2>", "<cmd>BufferLineGoToBuffer 2<CR>", { desc = "Go to buffer 2" })
      keymap("n", "<A-3>", "<cmd>BufferLineGoToBuffer 3<CR>", { desc = "Go to buffer 3" })
      keymap("n", "<A-4>", "<cmd>BufferLineGoToBuffer 4<CR>", { desc = "Go to buffer 4" })
      keymap("n", "<A-5>", "<cmd>BufferLineGoToBuffer 5<CR>", { desc = "Go to buffer 5" })
      keymap("n", "<A-6>", "<cmd>BufferLineGoToBuffer 6<CR>", { desc = "Go to buffer 6" })
      keymap("n", "<A-7>", "<cmd>BufferLineGoToBuffer 7<CR>", { desc = "Go to buffer 7" })
      keymap("n", "<A-8>", "<cmd>BufferLineGoToBuffer 8<CR>", { desc = "Go to buffer 8" })
      keymap("n", "<A-9>", "<cmd>BufferLineGoToBuffer 9<CR>", { desc = "Go to buffer 9" })

      -- Diagnostic navigation
      keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
      keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

      -- HLSlens (search)
      keymap('n', 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], { desc = "Next search result" })
      keymap('n', 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], { desc = "Previous search result" })
      keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], { desc = "Search word under cursor" })

      -- ─────────────────────────────────────────────────────────────
      -- Which-key organized keymaps
      -- ─────────────────────────────────────────────────────────────
      wk.add({
        -- Quick actions (no prefix)
        { "<leader>w", "<cmd>w<CR>", desc = "Save" },
        { "<leader>q", "<cmd>q<CR>", desc = "Quit" },
        { "<leader>Q", "<cmd>qa!<CR>", desc = "Quit all" },
        { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Explorer" },
        { "<leader>E", "<cmd>Neotree focus<CR>", desc = "Explorer focus" },
        { "<leader>?", "<cmd>WhichKey<CR>", desc = "Show all keybinds" },

        -- ═══════════════════════════════════════════════════════════
        -- [f]ind / [f]ile
        -- ═══════════════════════════════════════════════════════════
        { "<leader>f", group = "Find/File" },
        { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find file" },
        { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Find text (grep)" },
        { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffer" },
        { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
        { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands" },
        { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
        { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
        { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Find word under cursor" },
        { "<leader>fn", "<cmd>Telescope notify<CR>", desc = "Notifications" },

        -- ═══════════════════════════════════════════════════════════
        -- [b]uffer
        -- ═══════════════════════════════════════════════════════════
        { "<leader>b", group = "Buffer" },
        { "<leader>bd", "<cmd>lua require('mini.bufremove').delete(0, false)<CR>", desc = "Delete buffer" },
        { "<leader>bD", "<cmd>lua require('mini.bufremove').delete(0, true)<CR>", desc = "Delete buffer (force)" },
        { "<leader>bn", "<cmd>bnext<CR>", desc = "Next buffer" },
        { "<leader>bp", "<cmd>bprevious<CR>", desc = "Previous buffer" },
        { "<leader>bb", "<cmd>e #<CR>", desc = "Switch to other buffer" },
        { "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", desc = "Close other buffers" },

        -- ═══════════════════════════════════════════════════════════
        -- [g]it
        -- ═══════════════════════════════════════════════════════════
        { "<leader>g", group = "Git" },
        { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
        { "<leader>gn", "<cmd>Neogit<CR>", desc = "Neogit" },
        { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff view" },
        { "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "Close diff view" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
        { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Branch history" },
        { "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", desc = "Toggle line blame" },
        { "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", desc = "Preview hunk" },
        { "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset hunk" },
        { "<leader>gR", "<cmd>Gitsigns reset_buffer<CR>", desc = "Reset buffer" },
        { "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage hunk" },
        { "<leader>gS", "<cmd>Gitsigns stage_buffer<CR>", desc = "Stage buffer" },

        -- ═══════════════════════════════════════════════════════════
        -- [c]ode
        -- ═══════════════════════════════════════════════════════════
        { "<leader>c", group = "Code" },
        { "<leader>ca", vim.lsp.buf.code_action, desc = "Code action" },
        { "<leader>cr", vim.lsp.buf.rename, desc = "Rename symbol" },
        { "<leader>cf", function() require("conform").format() end, desc = "Format file" },
        { "<leader>cd", vim.diagnostic.open_float, desc = "Line diagnostics" },
        { "<leader>cs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols" },
        { "<leader>cS", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Workspace symbols" },

        -- ═══════════════════════════════════════════════════════════
        -- [l]sp
        -- ═══════════════════════════════════════════════════════════
        { "<leader>l", group = "LSP" },
        { "<leader>li", "<cmd>LspInfo<CR>", desc = "LSP info" },
        { "<leader>lr", "<cmd>LspRestart<CR>", desc = "LSP restart" },
        { "<leader>ll", "<cmd>LspLog<CR>", desc = "LSP log" },

        -- ═══════════════════════════════════════════════════════════
        -- [x] diagnostics/trouble
        -- ═══════════════════════════════════════════════════════════
        { "<leader>x", group = "Diagnostics" },
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (all)" },
        { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
        { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
        { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
        { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "TODOs" },

        -- ═══════════════════════════════════════════════════════════
        -- [s]earch
        -- ═══════════════════════════════════════════════════════════
        { "<leader>s", group = "Search" },
        { "<leader>sg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
        { "<leader>sr", "<cmd>lua require('spectre').open()<CR>", desc = "Search & Replace" },
        { "<leader>sw", "<cmd>lua require('spectre').open_visual({ select_word = true })<CR>", desc = "Search word" },
        { "<leader>sh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
        { "<leader>sm", "<cmd>Telescope marks<CR>", desc = "Marks" },
        { "<leader>sc", "<cmd>Telescope command_history<CR>", desc = "Command history" },

        -- ═══════════════════════════════════════════════════════════
        -- [u]i toggles
        -- ═══════════════════════════════════════════════════════════
        { "<leader>u", group = "UI Toggles" },
        { "<leader>un", "<cmd>set number!<CR>", desc = "Toggle line numbers" },
        { "<leader>ur", "<cmd>set relativenumber!<CR>", desc = "Toggle relative numbers" },
        { "<leader>uw", "<cmd>set wrap!<CR>", desc = "Toggle word wrap" },
        { "<leader>us", "<cmd>set spell!<CR>", desc = "Toggle spell check" },
        { "<leader>uc", "<cmd>set cursorline!<CR>", desc = "Toggle cursor line" },
        { "<leader>ud", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, desc = "Toggle diagnostics" },
        { "<leader>uh", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, desc = "Toggle inlay hints" },

        -- ═══════════════════════════════════════════════════════════
        -- [v]im learning - Cheatsheet and practice
        -- ═══════════════════════════════════════════════════════════
        { "<leader>v", group = "Vim Learning" },
        { "<leader>vc", function()
          local cheatsheet = [[
╔══════════════════════════════════════════════════════════════════════╗
║                     VIM CHEATSHEET - ESSENTIALS                      ║
╠══════════════════════════════════════════════════════════════════════╣
║ MODES (press Esc to go back to Normal mode)                          ║
║   i     → Insert mode (type text)     a → Insert after cursor        ║
║   v     → Visual mode (select)        V → Select whole lines         ║
║   :     → Command mode                / → Search mode                ║
║   jk    → Exit insert (custom)        Esc → Return to Normal         ║
╠══════════════════════════════════════════════════════════════════════╣
║ MOVEMENT (Normal mode)                                               ║
║   h j k l → Left/Down/Up/Right        w → Next word   b → Back word  ║
║   0     → Start of line               $ → End of line                ║
║   gg    → Top of file                 G → Bottom of file             ║
║   Ctrl+d → Page down                  Ctrl+u → Page up               ║
║   {  }  → Previous/Next paragraph     %  → Jump to matching bracket  ║
║   f{c}  → Jump to char {c}            F{c} → Jump back to char       ║
╠══════════════════════════════════════════════════════════════════════╣
║ EDITING (Normal mode)                                                ║
║   x     → Delete character            dd → Delete line               ║
║   yy    → Copy (yank) line            p  → Paste after cursor        ║
║   u     → Undo                        Ctrl+r → Redo                  ║
║   .     → Repeat last command         o  → New line below            ║
║   O     → New line above              A  → Insert at end of line     ║
║   ciw   → Change inner word           diw → Delete inner word        ║
║   cc    → Change whole line           C  → Change to end of line     ║
╠══════════════════════════════════════════════════════════════════════╣
║ VISUAL MODE (select text, then act)                                  ║
║   v     → Start selecting             V  → Select lines              ║
║   y     → Copy selection              d  → Delete selection          ║
║   >     → Indent right                <  → Indent left               ║
║   gc    → Toggle comment              gw → Format selection          ║
╠══════════════════════════════════════════════════════════════════════╣
║ SEARCH & REPLACE                                                     ║
║   /text → Search forward              ?text → Search backward        ║
║   n     → Next result                 N  → Previous result           ║
║   *     → Search word under cursor    :%s/old/new/g → Replace all    ║
╠══════════════════════════════════════════════════════════════════════╣
║ WINDOWS & BUFFERS                                                    ║
║   Ctrl+w v → Split vertical           Ctrl+w s → Split horizontal    ║
║   Ctrl+h/j/k/l → Navigate windows     Space bd → Close buffer        ║
║   Alt+1-9 → Go to buffer by number    Space bb → Switch buffer       ║
╠══════════════════════════════════════════════════════════════════════╣
║ YOUR LEADER KEYS (Space = Leader)                                    ║
║   Space ?  → Show ALL keybinds        Space e  → File explorer       ║
║   Space ff → Find file                Space fg → Find text (grep)    ║
║   Space w  → Save                     Space q  → Quit                ║
║   Space gg → LazyGit                  Space ca → Code actions        ║
║   gd       → Go to definition         K        → Show documentation  ║
╠══════════════════════════════════════════════════════════════════════╣
║ VS-CODE STYLE (your custom shortcuts)                                ║
║   Ctrl+s → Save    Ctrl+z → Undo    Ctrl+y → Redo    Ctrl+a → Select ║
║   Ctrl+c → Copy    Ctrl+x → Cut     Ctrl+v → Paste   Ctrl+d → Dupe   ║
║   Ctrl+f → Search  Ctrl+n → New     Ctrl+Shift+k → Delete line       ║
╚══════════════════════════════════════════════════════════════════════╝
          ]]
          -- Show in a floating window
          local buf = vim.api.nvim_create_buf(false, true)
          local lines = vim.split(cheatsheet, "\n")
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          local width = 76
          local height = #lines
          local win = vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = width,
            height = height,
            col = math.floor((vim.o.columns - width) / 2),
            row = math.floor((vim.o.lines - height) / 2),
            style = "minimal",
            border = "rounded",
          })
          vim.api.nvim_buf_set_option(buf, "modifiable", false)
          vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
        end, desc = "Show Vim Cheatsheet" },
        { "<leader>vt", "<cmd>Tutor<CR>", desc = "Start Vim Tutor" },
        { "<leader>vh", "<cmd>help<CR>", desc = "Open Vim Help" },
        { "<leader>vk", "<cmd>Telescope keymaps<CR>", desc = "Search Keymaps" },

        -- ═══════════════════════════════════════════════════════════
        -- [t]erminal
        -- ═══════════════════════════════════════════════════════════
        { "<leader>t", group = "Terminal" },
        { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
        { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Float terminal" },
        { "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Horizontal terminal" },
        { "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", desc = "Vertical terminal" },
        { "<leader>tg", "<cmd>lua require('toggleterm.terminal').Terminal:new({ cmd = 'lazygit', direction = 'float' }):toggle()<CR>", desc = "LazyGit (terminal)" },

        -- ═══════════════════════════════════════════════════════════
        -- [h]arpoon (quick file marks)
        -- ═══════════════════════════════════════════════════════════
        { "<leader>h", group = "Harpoon" },
        { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Add file" },
        { "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Toggle menu" },
        { "<leader>h1", function() require("harpoon"):list():select(1) end, desc = "File 1" },
        { "<leader>h2", function() require("harpoon"):list():select(2) end, desc = "File 2" },
        { "<leader>h3", function() require("harpoon"):list():select(3) end, desc = "File 3" },
        { "<leader>h4", function() require("harpoon"):list():select(4) end, desc = "File 4" },
        { "<leader>hp", function() require("harpoon"):list():prev() end, desc = "Previous file" },
        { "<leader>hn", function() require("harpoon"):list():next() end, desc = "Next file" },

        -- ═══════════════════════════════════════════════════════════
        -- [n]otifications
        -- ═══════════════════════════════════════════════════════════
        { "<leader>n", group = "Notifications" },
        { "<leader>nd", "<cmd>lua require('notify').dismiss()<CR>", desc = "Dismiss notifications" },
        { "<leader>nh", "<cmd>Telescope notify<CR>", desc = "Notification history" },

        -- ═══════════════════════════════════════════════════════════
        -- [<tab>] tabs
        -- ═══════════════════════════════════════════════════════════
        { "<leader><tab>", group = "Tabs" },
        { "<leader><tab>n", "<cmd>tabnew<CR>", desc = "New tab" },
        { "<leader><tab>d", "<cmd>tabclose<CR>", desc = "Close tab" },
        { "<leader><tab>]", "<cmd>tabnext<CR>", desc = "Next tab" },
        { "<leader><tab>[", "<cmd>tabprevious<CR>", desc = "Previous tab" },

        -- ═══════════════════════════════════════════════════════════
        -- Flash (jump navigation)
        -- ═══════════════════════════════════════════════════════════
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
        { "r", mode = "o", function() require("flash").remote() end, desc = "Flash remote" },

        -- ═══════════════════════════════════════════════════════════
        -- Oil (filesystem editor)
        -- ═══════════════════════════════════════════════════════════
        { "-", "<cmd>Oil<CR>", desc = "Open parent directory (Oil)" },

        -- ═══════════════════════════════════════════════════════════
        -- UFO (code folding)
        -- ═══════════════════════════════════════════════════════════
        { "zR", function() require('ufo').openAllFolds() end, desc = "Open all folds" },
        { "zM", function() require('ufo').closeAllFolds() end, desc = "Close all folds" },
        { "zK", function() require('ufo').peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
      })

      -- ─────────────────────────────────────────────────────────────
      -- LSP keymaps (on attach)
      -- ─────────────────────────────────────────────────────────────
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local opts = { buffer = args.buf }
          keymap('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = "Go to definition" }))
          keymap('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = "Go to declaration" }))
          keymap('n', 'gr', "<cmd>Telescope lsp_references<CR>", vim.tbl_extend('force', opts, { desc = "Go to references" }))
          keymap('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = "Go to implementation" }))
          keymap('n', 'gt', vim.lsp.buf.type_definition, vim.tbl_extend('force', opts, { desc = "Go to type definition" }))
          keymap('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = "Hover documentation" }))
          keymap('n', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = "Signature help" }))
          keymap('i', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = "Signature help" }))
        end,
      })

      -- ─────────────────────────────────────────────────────────────
      -- Auto commands
      -- ─────────────────────────────────────────────────────────────
      -- Highlight on yank
      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
          vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
        end,
      })

      -- Resize splits when window is resized
      vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
          vim.cmd("tabdo wincmd =")
        end,
      })

      -- Return to last edit position
      vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function()
          local mark = vim.api.nvim_buf_get_mark(0, '"')
          local lcount = vim.api.nvim_buf_line_count(0)
          if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
          end
        end,
      })

      -- Close some filetypes with <q>
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "help", "qf", "lspinfo", "notify", "checkhealth" },
        callback = function()
          vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, silent = true })
        end,
      })
    '';
  };
}
