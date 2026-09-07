{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  config = lib.mkIf (config.dev != "off") {
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # Align Nixvim nixpkgs source with Flint flake to prevent input warnings
      nixpkgs.source = inputs.nixpkgs;

      globals = {
        mapleader = " ";
        maplocalleader = " ";
        autoformat = true;
      };

      opts = {
        # Line numbers
        number = true;
        relativenumber = true;

        # Indentation (2 spaces)
        tabstop = 2;
        shiftwidth = 2;
        softtabstop = 2;
        expandtab = true;
        smartindent = true;
        shiftround = true;

        # Search & UI
        ignorecase = true;
        smartcase = true;
        cursorline = true;
        termguicolors = true;
        signcolumn = "yes";
        wrap = false;
        scrolloff = 8;
        sidescrolloff = 8;

        # Splits
        splitbelow = true;
        splitright = true;

        # System & Performance
        mouse = "a";
        clipboard = "unnamedplus";
        undofile = true;
        undolevels = 10000;
        timeoutlen = 300;
        updatetime = 200;
        confirm = true;
      };

      extraPlugins = with pkgs.vimPlugins; [
        mini-nvim
      ];

      # Gruvbox Colorscheme for Enhanced Readability & Contrast
      colorschemes.gruvbox = {
        enable = true;
        settings = {
          contrast = "hard";
          transparent_mode = false;
          bold = true;
          italic = {
            strings = true;
            emphasis = true;
            comments = true;
            operators = false;
            folds = true;
          };
        };
      };

      # LazyVim Which-Key Groups, Indentscope Disabler & Helper Commands
      extraConfigLua = ''
        -- Disable mini.indentscope on dashboard and utility buffers (removes awkward dashed line)
        vim.api.nvim_create_autocmd("FileType", {
          pattern = {
            "snacks_dashboard",
            "snacks_notif",
            "snacks_terminal",
            "snacks_win",
            "neo-tree",
            "Trouble",
            "trouble",
            "help",
            "lazy",
            "notify",
            "toggleterm",
          },
          callback = function()
            vim.b.miniindentscope_disable = true
          end,
        })

        -- LazyVim Which-Key Group Specifications
        local wk = require("which-key")
        wk.add({
          { "<leader>b", group = "Buffer", icon = "󰓩 " },
          { "<leader>c", group = "Code", icon = "󰅩 " },
          { "<leader>f", group = "File/Find", icon = "󰈞 " },
          { "<leader>g", group = "Git", icon = "󰊢 " },
          { "<leader>gh", group = "Hunks", icon = "󰊢 " },
          { "<leader>q", group = "Quit/Session", icon = " " },
          { "<leader>s", group = "Search", icon = "󰍉 " },
          { "<leader>sn", group = "Noice", icon = "󰍡 " },
          { "<leader>u", group = "UI", icon = "󰙵 " },
          { "<leader>w", group = "Windows", icon = "󱂬 " },
          { "<leader>x", group = "Diagnostics/Trouble", icon = "󱍼 " },
          { "[", group = "Prev" },
          { "]", group = "Next" },
          { "g", group = "Goto" },
        })

        -- Informative LazyVim / Nixvim Manager Command
        vim.api.nvim_create_user_command("Lazy", function()
          local lines = {
            "  󰒲  LazyVim (Nixvim Edition) - Flint OS",
            "  ──────────────────────────────────────────",
            "  Plugins are deterministically managed via Nix Flakes.",
            "  Run 'nh os switch' to rebuild / update your environment.",
            "",
            "  Active Core Modules:",
            "  • Snacks.nvim (Dashboard, Terminal, Bufdelete, Words, Bigfile)",
            "  • Neo-Tree (Filesystem Explorer)",
            "  • Telescope (Fuzzy Finders & Pickers)",
            "  • Which-Key (LazyVim Grouped Mappings)",
            "  • Flash.nvim (Bidirectional Navigation)",
            "  • Lualine & Bufferline (Brutalist Monochrome)",
            "  • Treesitter & Context Highlighting",
            "  • LSP (nil, lua_ls, rust, go, ts, pyright, bash)",
            "  • CMP & Luasnip & Friendly-Snippets",
            "  • Conform (alejandra, stylua, prettier)",
            "  • Lazygit & Gitsigns & Diffview",
            "  • Noice & Notify (Centric Command Palette)",
            "  • Persistence (Session Restoration)",
          }
          vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LazyVim Plugins" })
        end, {})
      '';

      plugins = {
        # LazyVim Core Suite (Snacks.nvim)
        snacks = {
          enable = true;
          settings = {
            bigfile.enabled = true;
            quickfile.enabled = true;
            words.enabled = true;
            terminal.enabled = true;
            bufdelete.enabled = true;
            lazygit.enabled = true;
            statuscolumn.enabled = false;
            dashboard = {
              enabled = true;
              preset = {
                header = ''
                   ______ _      _____ _   _ _______
                  |  ____| |    |_   _| \ | |__   __|
                  | |__  | |      | | |  \| |  | |
                  |  __| | |      | | | . ` |  | |
                  | |    | |____ _| |_| |\  |  | |
                  |_|    |______|_____|_| \_|  |_|
                '';
                keys = [
                  {
                    icon = " ";
                    key = "f";
                    desc = "Find File";
                    action = ":Telescope find_files";
                  }
                  {
                    icon = " ";
                    key = "n";
                    desc = "New File";
                    action = ":ene | startinsert";
                  }
                  {
                    icon = " ";
                    key = "r";
                    desc = "Recent Files";
                    action = ":Telescope oldfiles";
                  }
                  {
                    icon = " ";
                    key = "g";
                    desc = "Find Text";
                    action = ":Telescope live_grep";
                  }
                  {
                    icon = " ";
                    key = "c";
                    desc = "Config";
                    action = ":lua require('telescope.builtin').find_files({ cwd = vim.fn.expand('~/.config/flint') })";
                  }
                  {
                    icon = " ";
                    key = "s";
                    desc = "Restore Session";
                    action = ":lua require('persistence').load()";
                  }
                  {
                    icon = "󰒲 ";
                    key = "l";
                    desc = "Lazy / Plugins";
                    action = ":Lazy";
                  }
                  {
                    icon = " ";
                    key = "q";
                    desc = "Quit";
                    action = ":qa";
                  }
                ];
              };
              sections = [
                {section = "header";}
                {
                  section = "keys";
                  gap = 1;
                  padding = 1;
                }
                {
                  align = "center";
                  hl = "SnacksDashboardFooter";
                  padding = 1;
                  text = "⚡ Flint Neovim · Gruvbox Edition";
                }
              ];
            };
          };
        };

        # LazyVim Statusline (Gruvbox)
        lualine = {
          enable = true;
          settings = {
            options = {
              icons_enabled = true;
              theme = "gruvbox";
              component_separators = {
                left = "│";
                right = "│";
              };
              section_separators = {
                left = "";
                right = "";
              };
              globalstatus = true;
            };
            sections = {
              lualine_a = ["mode"];
              lualine_b = ["branch" "diff"];
              lualine_c = [
                {
                  __unkeyed-1 = "filename";
                  path = 1;
                  symbols = {
                    modified = " 󰝤";
                    readonly = " 󰌾";
                    unnamed = "[No Name]";
                  };
                }
              ];
              lualine_x = [
                {
                  __unkeyed-1 = "diagnostics";
                  sources = ["nvim_lsp"];
                }
                "filetype"
              ];
              lualine_y = ["progress"];
              lualine_z = ["location"];
            };
          };
        };

        # Buffer Tabs (Bufferline)
        bufferline = {
          enable = true;
          settings = {
            options = {
              mode = "buffers";
              always_show_bufferline = false;
              diagnostics = "nvim_lsp";
              show_buffer_close_icons = true;
              show_close_icon = false;
              offsets = [
                {
                  filetype = "neo-tree";
                  text = "Explorer";
                  highlight = "Directory";
                  text_align = "left";
                }
              ];
            };
          };
        };

        # File Tree (Neo-Tree)
        neo-tree = {
          enable = true;
          settings = {
            enable_git_status = true;
            enable_diagnostics = true;
            filesystem = {
              follow_current_file.enabled = true;
              use_libuv_file_watcher = true;
              bind_to_cwd = false;
            };
            window = {
              width = 30;
              mappings = {
                "<space>" = "none";
              };
            };
          };
        };

        # Fuzzy Finder (Telescope)
        telescope = {
          enable = true;
        };

        # UI Components & Popups (Folke Suite)
        which-key.enable = true;
        dressing.enable = true;
        noice = {
          enable = true;
          settings = {
            lsp = {
              override = {
                "vim.lsp.util.convert_input_to_markdown_lines" = true;
                "vim.lsp.util.set_lines" = true;
                "cmp.entry.get_documentation" = true;
              };
            };
            presets = {
              bottom_search = true;
              command_palette = true;
              long_message_to_split = true;
              inc_rename = true;
            };
          };
        };
        notify.enable = true;
        todo-comments.enable = true;
        persistence.enable = true;
        trouble.enable = true;
        flash.enable = true;
        web-devicons.enable = true;

        # Treesitter Syntax Highlighting
        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
        };
        treesitter-context.enable = true;

        # Git Integration (Gitsigns)
        gitsigns = {
          enable = true;
          settings = {
            current_line_blame = false;
            signs = {
              add = {text = "▎";};
              change = {text = "▎";};
              delete = {text = "";};
              topdelete = {text = "";};
              changedelete = {text = "▎";};
            };
          };
        };

        # Code Formatting (Conform)
        conform-nvim = {
          enable = true;
          settings = {
            format_on_save = {
              timeout_ms = 500;
              lsp_format = "fallback";
            };
            formatters_by_ft = {
              nix = ["alejandra"];
              lua = ["stylua"];
              javascript = ["prettier"];
              typescript = ["prettier"];
              javascriptreact = ["prettier"];
              typescriptreact = ["prettier"];
              json = ["prettier"];
              yaml = ["prettier"];
              css = ["prettier"];
              html = ["prettier"];
              markdown = ["prettier"];
            };
          };
        };

        # Autocompletion & Snippets (CMP)
        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            sources = [
              {name = "nvim_lsp";}
              {name = "buffer";}
              {name = "path";}
              {name = "treesitter";}
              {name = "luasnip";}
            ];
            mapping = {
              "<C-Space>" = "cmp.mapping.complete()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<Tab>" = "cmp.mapping.select_next_item()";
              "<S-Tab>" = "cmp.mapping.select_prev_item()";
              "<C-j>" = "cmp.mapping.select_next_item()";
              "<C-k>" = "cmp.mapping.select_prev_item()";
            };
          };
        };
        luasnip.enable = true;
        friendly-snippets.enable = true;
        lspkind.enable = true;

        # Language Server Protocol (LSP)
        lsp = {
          enable = true;
          inlayHints = true;
          servers = {
            nil_ls.enable = true;
            lua_ls.enable = true;
            bashls.enable = true;
            rust_analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
            };
            gopls.enable = true;
            pyright.enable = true;
            ts_ls.enable = true;
            html.enable = true;
            cssls.enable = true;
            yamlls.enable = true;
            jsonls.enable = true;
            taplo.enable = true;
          };
        };

        # Mini Utilities & Editing Comforts
        mini = {
          enable = true;
          mockDevIcons = true;
          modules = {
            ai = {};
            bufremove = {};
            icons = {};
            indentscope = {};
            pairs = {};
            surround = {};
          };
        };

        # Visuals
        indent-blankline = {
          enable = true;
          settings = {
            exclude = {
              filetypes = [
                ""
                "checkhealth"
                "help"
                "lspinfo"
                "man"
                "neo-tree"
                "notify"
                "snacks_dashboard"
                "snacks_notif"
                "snacks_terminal"
                "snacks_win"
                "TelescopePrompt"
                "TelescopeResults"
                "trouble"
                "Trouble"
              ];
            };
          };
        };
        rainbow-delimiters.enable = true;
        colorizer.enable = true;
        diffview.enable = true;
        comment.enable = true;
      };

      # Complete LazyVim Keymaps
      keymaps = [
        # --- File Explorer ---
        {
          key = "<leader>e";
          mode = "n";
          action = "<cmd>Neotree toggle<CR>";
          options.desc = "Explorer NeoTree (Root Dir)";
        }
        {
          key = "<leader>fe";
          mode = "n";
          action = "<cmd>Neotree toggle<CR>";
          options.desc = "Explorer NeoTree (Root Dir)";
        }

        # --- LazyVim Search & Finders ---
        {
          key = "<leader><space>";
          mode = "n";
          action = "<cmd>Telescope find_files<CR>";
          options.desc = "Find Files (Root Dir)";
        }
        {
          key = "<leader>/";
          mode = "n";
          action = "<cmd>Telescope live_grep<CR>";
          options.desc = "Grep (Root Dir)";
        }
        {
          key = "<leader>,";
          mode = "n";
          action = "<cmd>Telescope buffers<CR>";
          options.desc = "Switch Buffer";
        }
        {
          key = "<leader>:";
          mode = "n";
          action = "<cmd>Telescope command_history<CR>";
          options.desc = "Command History";
        }
        {
          key = "<leader>ff";
          mode = "n";
          action = "<cmd>Telescope find_files<CR>";
          options.desc = "Find Files";
        }
        {
          key = "<leader>fg";
          mode = "n";
          action = "<cmd>Telescope git_files<CR>";
          options.desc = "Find Files (git-files)";
        }
        {
          key = "<leader>fr";
          mode = "n";
          action = "<cmd>Telescope oldfiles<CR>";
          options.desc = "Recent Files";
        }
        {
          key = "<leader>fb";
          mode = "n";
          action = "<cmd>Telescope buffers<CR>";
          options.desc = "Buffers";
        }
        {
          key = "<leader>fc";
          mode = "n";
          action = "<cmd>lua require('telescope.builtin').find_files({ cwd = vim.fn.expand('~/.config/flint') })<CR>";
          options.desc = "Find Config Files";
        }
        {
          key = "<leader>fn";
          mode = "n";
          action = "<cmd>enew<CR>";
          options.desc = "New File";
        }
        {
          key = "<leader>s\"";
          mode = "n";
          action = "<cmd>Telescope registers<CR>";
          options.desc = "Registers";
        }
        {
          key = "<leader>sa";
          mode = "n";
          action = "<cmd>Telescope autocommands<CR>";
          options.desc = "Auto Commands";
        }
        {
          key = "<leader>sb";
          mode = "n";
          action = "<cmd>Telescope current_buffer_fuzzy_find<CR>";
          options.desc = "Buffer Lines";
        }
        {
          key = "<leader>sc";
          mode = "n";
          action = "<cmd>Telescope command_history<CR>";
          options.desc = "Command History";
        }
        {
          key = "<leader>sC";
          mode = "n";
          action = "<cmd>Telescope commands<CR>";
          options.desc = "Commands";
        }
        {
          key = "<leader>sd";
          mode = "n";
          action = "<cmd>Telescope diagnostics bufnr=0<CR>";
          options.desc = "Document Diagnostics";
        }
        {
          key = "<leader>sD";
          mode = "n";
          action = "<cmd>Telescope diagnostics<CR>";
          options.desc = "Workspace Diagnostics";
        }
        {
          key = "<leader>sg";
          mode = "n";
          action = "<cmd>Telescope live_grep<CR>";
          options.desc = "Grep";
        }
        {
          key = "<leader>sw";
          mode = "n";
          action = "<cmd>Telescope grep_string<CR>";
          options.desc = "Word";
        }
        {
          key = "<leader>sh";
          mode = "n";
          action = "<cmd>Telescope help_tags<CR>";
          options.desc = "Help Pages";
        }
        {
          key = "<leader>sk";
          mode = "n";
          action = "<cmd>Telescope keymaps<CR>";
          options.desc = "Key Maps";
        }
        {
          key = "<leader>sm";
          mode = "n";
          action = "<cmd>Telescope marks<CR>";
          options.desc = "Jump to Mark";
        }
        {
          key = "<leader>st";
          mode = "n";
          action = "<cmd>TodoTelescope<CR>";
          options.desc = "Todo";
        }
        {
          key = "<leader>uC";
          mode = "n";
          action = "<cmd>Telescope colorscheme enable_preview=true<CR>";
          options.desc = "Colorscheme with Preview";
        }

        # --- LazyVim Buffer Management ---
        {
          key = "<S-h>";
          mode = "n";
          action = "<cmd>bprevious<CR>";
          options.desc = "Prev Buffer";
        }
        {
          key = "<S-l>";
          mode = "n";
          action = "<cmd>bnext<CR>";
          options.desc = "Next Buffer";
        }
        {
          key = "[b";
          mode = "n";
          action = "<cmd>bprevious<CR>";
          options.desc = "Prev Buffer";
        }
        {
          key = "]b";
          mode = "n";
          action = "<cmd>bnext<CR>";
          options.desc = "Next Buffer";
        }
        {
          key = "<leader>bd";
          mode = "n";
          action = "<cmd>lua Snacks.bufdelete()<CR>";
          options.desc = "Delete Buffer";
        }
        {
          key = "<leader>bD";
          mode = "n";
          action = "<cmd>lua Snacks.bufdelete({ force = true })<CR>";
          options.desc = "Delete Buffer (Force)";
        }
        {
          key = "<leader>bp";
          mode = "n";
          action = "<cmd>BufferLineTogglePin<CR>";
          options.desc = "Toggle Pin";
        }
        {
          key = "<leader>bP";
          mode = "n";
          action = "<cmd>BufferLineGroupClose ungrouped<CR>";
          options.desc = "Delete Non-Pinned Buffers";
        }
        {
          key = "<leader>bo";
          mode = "n";
          action = "<cmd>BufferLineCloseOthers<CR>";
          options.desc = "Delete Other Buffers";
        }
        {
          key = "<leader>bl";
          mode = "n";
          action = "<cmd>BufferLineCloseLeft<CR>";
          options.desc = "Close Buffers to the Left";
        }
        {
          key = "<leader>br";
          mode = "n";
          action = "<cmd>BufferLineCloseRight<CR>";
          options.desc = "Close Buffers to the Right";
        }
        {
          key = "<leader>bb";
          mode = "n";
          action = "<cmd>Telescope buffers<CR>";
          options.desc = "Switch Buffer";
        }

        # --- Window Navigation & Splits ---
        {
          key = "<C-h>";
          mode = "n";
          action = "<C-w>h";
          options.desc = "Go to Left Window";
        }
        {
          key = "<C-j>";
          mode = "n";
          action = "<C-w>j";
          options.desc = "Go to Lower Window";
        }
        {
          key = "<C-k>";
          mode = "n";
          action = "<C-w>k";
          options.desc = "Go to Upper Window";
        }
        {
          key = "<C-l>";
          mode = "n";
          action = "<C-w>l";
          options.desc = "Go to Right Window";
        }
        {
          key = "<leader>-";
          mode = "n";
          action = "<C-W>s";
          options.desc = "Split Window Below";
        }
        {
          key = "<leader>|";
          mode = "n";
          action = "<C-W>v";
          options.desc = "Split Window Right";
        }
        {
          key = "<leader>wd";
          mode = "n";
          action = "<C-W>c";
          options.desc = "Delete Window";
        }
        {
          key = "<leader>wm";
          mode = "n";
          action = "<C-W>| <C-W>_";
          options.desc = "Maximize Window";
        }

        # --- Window Resize with Arrows ---
        {
          key = "<C-Up>";
          mode = "n";
          action = "<cmd>resize +2<CR>";
          options.desc = "Increase Window Height";
        }
        {
          key = "<C-Down>";
          mode = "n";
          action = "<cmd>resize -2<CR>";
          options.desc = "Decrease Window Height";
        }
        {
          key = "<C-Left>";
          mode = "n";
          action = "<cmd>vertical resize -2<CR>";
          options.desc = "Decrease Window Width";
        }
        {
          key = "<C-Right>";
          mode = "n";
          action = "<cmd>vertical resize +2<CR>";
          options.desc = "Increase Window Width";
        }

        # --- LazyVim Line Moving (Bubbling) ---
        {
          key = "<A-j>";
          mode = "n";
          action = "<cmd>m .+1<cr>==";
          options.desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = "n";
          action = "<cmd>m .-2<cr>==";
          options.desc = "Move Up";
        }
        {
          key = "<A-j>";
          mode = "i";
          action = "<esc><cmd>m .+1<cr>==gi";
          options.desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = "i";
          action = "<esc><cmd>m .-2<cr>==gi";
          options.desc = "Move Up";
        }
        {
          key = "<A-j>";
          mode = "v";
          action = ":m '>+1<CR>gv=gv";
          options.desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = "v";
          action = ":m '<-2<CR>gv=gv";
          options.desc = "Move Up";
        }

        # --- Indenting (Stay in Visual Mode) ---
        {
          key = "<";
          mode = "v";
          action = "<gv";
          options.desc = "Indent Left";
        }
        {
          key = ">";
          mode = "v";
          action = ">gv";
          options.desc = "Indent Right";
        }

        # --- Clear Search on Escape ---
        {
          key = "<esc>";
          mode = "n";
          action = "<cmd>noh<CR><esc>";
          options.desc = "Escape and Clear hlsearch";
        }

        # --- LazyVim Word Navigation (Snacks Words) ---
        {
          key = "]]";
          mode = "n";
          action = "<cmd>lua Snacks.words.jump(1, true)<CR>";
          options.desc = "Next Reference";
        }
        {
          key = "[[";
          mode = "n";
          action = "<cmd>lua Snacks.words.jump(-1, true)<CR>";
          options.desc = "Prev Reference";
        }

        # --- Code & LSP Actions ---
        {
          key = "<leader>ca";
          mode = [
            "n"
            "v"
          ];
          action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
          options.desc = "Code Action";
        }
        {
          key = "<leader>cr";
          mode = "n";
          action = "<cmd>lua vim.lsp.buf.rename()<CR>";
          options.desc = "Rename";
        }
        {
          key = "<leader>cf";
          mode = [
            "n"
            "v"
          ];
          action = "<cmd>lua require('conform').format({ async = true, lsp_format = 'fallback' })<CR>";
          options.desc = "Format Document";
        }
        {
          key = "<leader>cd";
          mode = "n";
          action = "<cmd>lua vim.diagnostic.open_float()<CR>";
          options.desc = "Line Diagnostics";
        }
        {
          key = "gd";
          mode = "n";
          action = "<cmd>lua vim.lsp.buf.definition()<CR>";
          options.desc = "Goto Definition";
        }
        {
          key = "gr";
          mode = "n";
          action = "<cmd>lua vim.lsp.buf.references()<CR>";
          options.desc = "References";
        }
        {
          key = "gI";
          mode = "n";
          action = "<cmd>lua vim.lsp.buf.implementation()<CR>";
          options.desc = "Goto Implementation";
        }
        {
          key = "gy";
          mode = "n";
          action = "<cmd>lua vim.lsp.buf.type_definition()<CR>";
          options.desc = "Goto Type Definition";
        }
        {
          key = "gD";
          mode = "n";
          action = "<cmd>lua vim.lsp.buf.declaration()<CR>";
          options.desc = "Goto Declaration";
        }
        {
          key = "K";
          mode = "n";
          action = "<cmd>lua vim.lsp.buf.hover()<CR>";
          options.desc = "Hover";
        }
        {
          key = "gK";
          mode = "n";
          action = "<cmd>lua vim.lsp.buf.signature_help()<CR>";
          options.desc = "Signature Help";
        }
        {
          key = "<C-k>";
          mode = "i";
          action = "<cmd>lua vim.lsp.buf.signature_help()<CR>";
          options.desc = "Signature Help";
        }
        {
          key = "[d";
          mode = "n";
          action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
          options.desc = "Prev Diagnostic";
        }
        {
          key = "]d";
          mode = "n";
          action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
          options.desc = "Next Diagnostic";
        }
        {
          key = "[e";
          mode = "n";
          action = "<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<CR>";
          options.desc = "Prev Error";
        }
        {
          key = "]e";
          mode = "n";
          action = "<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<CR>";
          options.desc = "Next Error";
        }
        {
          key = "[w";
          mode = "n";
          action = "<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })<CR>";
          options.desc = "Prev Warning";
        }
        {
          key = "]w";
          mode = "n";
          action = "<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })<CR>";
          options.desc = "Next Warning";
        }

        # --- Diagnostics & Trouble ---
        {
          key = "<leader>xx";
          mode = "n";
          action = "<cmd>Trouble diagnostics toggle<CR>";
          options.desc = "Diagnostics (Trouble)";
        }
        {
          key = "<leader>xX";
          mode = "n";
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
          options.desc = "Buffer Diagnostics (Trouble)";
        }
        {
          key = "<leader>cs";
          mode = "n";
          action = "<cmd>Trouble symbols toggle focus=false<CR>";
          options.desc = "Symbols (Trouble)";
        }
        {
          key = "<leader>xL";
          mode = "n";
          action = "<cmd>Trouble loclist toggle<CR>";
          options.desc = "Location List (Trouble)";
        }
        {
          key = "<leader>xQ";
          mode = "n";
          action = "<cmd>Trouble qflist toggle<CR>";
          options.desc = "Quickfix List (Trouble)";
        }

        # --- Git (Lazygit, Gitsigns & Diffview) ---
        {
          key = "<leader>gg";
          mode = "n";
          action = "<cmd>lua Snacks.lazygit()<CR>";
          options.desc = "Lazygit (Root Dir)";
        }
        {
          key = "]h";
          mode = "n";
          action = "<cmd>Gitsigns next_hunk<CR>";
          options.desc = "Next Hunk";
        }
        {
          key = "[h";
          mode = "n";
          action = "<cmd>Gitsigns prev_hunk<CR>";
          options.desc = "Prev Hunk";
        }
        {
          key = "<leader>ghp";
          mode = "n";
          action = "<cmd>Gitsigns preview_hunk<CR>";
          options.desc = "Preview Hunk";
        }
        {
          key = "<leader>ghb";
          mode = "n";
          action = "<cmd>Gitsigns blame_line<CR>";
          options.desc = "Blame Line";
        }
        {
          key = "<leader>ghd";
          mode = "n";
          action = "<cmd>DiffviewOpen<CR>";
          options.desc = "Diff View";
        }
        {
          key = "<leader>ghs";
          mode = "n";
          action = "<cmd>Gitsigns stage_hunk<CR>";
          options.desc = "Stage Hunk";
        }
        {
          key = "<leader>ghr";
          mode = "n";
          action = "<cmd>Gitsigns reset_hunk<CR>";
          options.desc = "Reset Hunk";
        }
        {
          key = "<leader>ghS";
          mode = "n";
          action = "<cmd>Gitsigns stage_buffer<CR>";
          options.desc = "Stage Buffer";
        }
        {
          key = "<leader>ghu";
          mode = "n";
          action = "<cmd>Gitsigns undo_stage_hunk<CR>";
          options.desc = "Undo Stage Hunk";
        }
        {
          key = "<leader>ghR";
          mode = "n";
          action = "<cmd>Gitsigns reset_buffer<CR>";
          options.desc = "Reset Buffer";
        }

        # --- UI Toggles (<leader>u) ---
        {
          key = "<leader>uf";
          mode = "n";
          action = "<cmd>lua vim.g.autoformat = not (vim.g.autoformat == nil and false or vim.g.autoformat); print('Autoformat: ' .. tostring(vim.g.autoformat))<CR>";
          options.desc = "Toggle Autoformat";
        }
        {
          key = "<leader>us";
          mode = "n";
          action = "<cmd>setlocal spell!<CR>";
          options.desc = "Toggle Spelling";
        }
        {
          key = "<leader>uw";
          mode = "n";
          action = "<cmd>setlocal wrap!<CR>";
          options.desc = "Toggle Wrap";
        }
        {
          key = "<leader>ul";
          mode = "n";
          action = "<cmd>setlocal number!<CR>";
          options.desc = "Toggle Line Numbers";
        }
        {
          key = "<leader>uL";
          mode = "n";
          action = "<cmd>setlocal relativenumber!<CR>";
          options.desc = "Toggle Relative Numbers";
        }
        {
          key = "<leader>ud";
          mode = "n";
          action = "<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<CR>";
          options.desc = "Toggle Diagnostics";
        }
        {
          key = "<leader>uh";
          mode = "n";
          action = "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<CR>";
          options.desc = "Toggle Inlay Hints";
        }
        {
          key = "<leader>ut";
          mode = "n";
          action = "<cmd>TSContextToggle<CR>";
          options.desc = "Toggle Treesitter Context";
        }
        {
          key = "<leader>un";
          mode = "n";
          action = "<cmd>lua require('notify').dismiss({ silent = true, pending = true })<CR>";
          options.desc = "Dismiss Notifications";
        }

        # --- Terminal (<leader>ft, <C-/>, <C-_>) ---
        {
          key = "<C-/>";
          mode = "n";
          action = "<cmd>lua Snacks.terminal()<CR>";
          options.desc = "Toggle Terminal";
        }
        {
          key = "<C-_>";
          mode = "n";
          action = "<cmd>lua Snacks.terminal()<CR>";
          options.desc = "Toggle Terminal";
        }
        {
          key = "<leader>ft";
          mode = "n";
          action = "<cmd>lua Snacks.terminal()<CR>";
          options.desc = "Terminal (Root Dir)";
        }
        {
          key = "<C-/>";
          mode = "t";
          action = "<cmd>lua Snacks.terminal()<CR>";
          options.desc = "Toggle Terminal";
        }
        {
          key = "<C-_>";
          mode = "t";
          action = "<cmd>lua Snacks.terminal()<CR>";
          options.desc = "Toggle Terminal";
        }
        {
          key = "<esc><esc>";
          mode = "t";
          action = "<C-\\><C-n>";
          options.desc = "Exit Terminal Mode";
        }

        # --- Flash Navigation (s, S) ---
        {
          key = "s";
          mode = [
            "n"
            "x"
            "o"
          ];
          action = "<cmd>lua require('flash').jump()<CR>";
          options.desc = "Flash";
        }
        {
          key = "S";
          mode = [
            "n"
            "x"
            "o"
          ];
          action = "<cmd>lua require('flash').treesitter()<CR>";
          options.desc = "Flash Treesitter";
        }
        {
          key = "r";
          mode = "o";
          action = "<cmd>lua require('flash').remote()<CR>";
          options.desc = "Remote Flash";
        }
        {
          key = "R";
          mode = [
            "o"
            "x"
          ];
          action = "<cmd>lua require('flash').treesitter_search()<CR>";
          options.desc = "Treesitter Search";
        }
        {
          key = "<c-s>";
          mode = "c";
          action = "<cmd>lua require('flash').toggle()<CR>";
          options.desc = "Toggle Flash Search";
        }

        # --- Noice Messages (<leader>sn) ---
        {
          key = "<leader>snl";
          mode = "n";
          action = "<cmd>Noice last<CR>";
          options.desc = "Noice Last Message";
        }
        {
          key = "<leader>snh";
          mode = "n";
          action = "<cmd>Noice history<CR>";
          options.desc = "Noice History";
        }
        {
          key = "<leader>sna";
          mode = "n";
          action = "<cmd>Noice all<CR>";
          options.desc = "Noice All";
        }
        {
          key = "<leader>snd";
          mode = "n";
          action = "<cmd>Noice dismiss<CR>";
          options.desc = "Dismiss Notifications";
        }

        # --- Session (Persistence) ---
        {
          key = "<leader>qs";
          mode = "n";
          action = "<cmd>lua require('persistence').load()<CR>";
          options.desc = "Restore Session";
        }
        {
          key = "<leader>ql";
          mode = "n";
          action = "<cmd>lua require('persistence').load({ last = true })<CR>";
          options.desc = "Restore Last Session";
        }
        {
          key = "<leader>qd";
          mode = "n";
          action = "<cmd>lua require('persistence').stop()<CR>";
          options.desc = "Don't Save Current Session";
        }

        # --- Quick Save & Quit ---
        {
          key = "<leader>w";
          mode = "n";
          action = "<cmd>w<CR>";
          options.desc = "Save File";
        }
        {
          key = "<leader>q";
          mode = "n";
          action = "<cmd>q<CR>";
          options.desc = "Quit";
        }
        {
          key = "<leader>qq";
          mode = "n";
          action = "<cmd>qa<CR>";
          options.desc = "Quit All";
        }
      ];
    };
  };
}
