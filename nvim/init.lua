--------------------------------------------------------------------------------
vim.g.mapleader = " "

-- Custom statusline
require("statusline")

-- Gui
vim.g.netrw_banner = 0
vim.o.number = true
vim.o.relativenumber = true
vim.opt.guicursor = { "n-v:block", "i-c:block-blinkon500-blinkoff500" }
vim.o.scrolloff = 8
vim.o.colorcolumn = "81"
vim.o.signcolumn = "yes"
vim.o.winborder = "single"
vim.o.termguicolors = true

-- Text
vim.o.tabstop = 2
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.wrap = false
vim.o.smartindent = true
vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true

-- Misc
vim.o.swapfile = false
vim.o.backup = false
vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.o.undofile = true
vim.o.confirm = true

--- Remaps
vim.keymap.set({ "n", "i", "v", "x", "s", "o" }, "<C-c>", "<Esc>", { silent = true })
-- vim.keymap.set("n", "<leader>nw", vim.cmd.Ex)
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "G", "Gzz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set({ "n", "v", "x" }, "<leader>y", [["+y]])
vim.keymap.set({ "n", "v", "x" }, "<leader>d", [["+d]])
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww ~/.local/bin/tmux-sessionizer<CR>")

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.highlight.on_yank() end,
})

--------------------------------------------------------------------------------
-- Pack
vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  { src = "https://github.com/mbbill/undotree" },
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
  { src = "https://github.com/slugbyte/lackluster.nvim" },
  { src = "https://github.com/ThePrimeagen/harpoon" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter",          version = "main",                  build = ":TSUpdate" },
  { src = "https://github.com/L3MON4D3/LuaSnip" },
  { src = "https://github.com/saghen/blink.cmp",                         version = vim.version.range("1.*") },
  { src = "https://github.com/github/copilot.vim" },
  { src = "https://github.com/stevearc/oil.nvim" },
})

-- Treesitter
--------------------------------------------------------------------------------
local treesitter_languages = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "javascript",
  "typescript",
  "tsx",
  "c",
  "cpp",
  "cmake",
  "json",
  "yaml",
  "css",
  "markdown",
  "markdown_inline",
  "bash",
  "toml",
}

require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

require("nvim-treesitter").install(treesitter_languages)

vim.api.nvim_create_autocmd('FileType', {
  callback = function() pcall(vim.treesitter.start) end,
})

--------------------------------------------------------------------------------
--- LSP
vim.lsp.enable({ "lua_ls", "ts_ls", "eslint", "rust_analyzer", "clangd", })
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      }
    }
  }
})

vim.keymap.set("n", "grd", vim.lsp.buf.definition, { silent = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "html", "css", },
  callback = function()
    vim.bo.formatprg = "prettier --stdin-filepath %"
  end,
})

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "cmake",
--   callback = function()
--     vim.bo.formatprg = "cmake-format -"
--   end,
-- })

--------------------------------------------------------------------------------
--- Telescope
local square_borders = { "─", "│", "─", "│", "┌", "┐", "┘", "└" }

require "telescope".setup({
  defaults = {
    preview = { treesitter = true },
    mappings = {
      n = {
        ["<C-c>"] = require("telescope.actions").close,
      },
    },
    file_ignore_patterns = { ".DS_Store", "build/", "node_modules/", "target/", ".git/", ".cache/", ".next/" },
  },

  pickers = {
    find_files = {
      theme = "dropdown",
      borderchars = square_borders,
      no_ignore = true,
      hidden = true,
    },
    live_grep = {
      theme = "dropdown",
      borderchars = square_borders,
    },
    help_tags = {
      theme = "dropdown",
      borderchars = square_borders,
    },
    diagnostics = {
      theme = "dropdown",
      borderchars = square_borders,
    },
  },

  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  },
})

vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>")
vim.keymap.set("n", "<leader>gr", ":Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>ht", ":Telescope help_tags<CR>")
vim.keymap.set("n", "<leader>vd", ":Telescope diagnostics<CR>")

--------------------------------------------------------------------------------
--- Colorscheme
local color = require("lackluster").color

require("lackluster").setup({
  tweak_color = {
    red = "#aa6666",
  },
  tweak_highlight = {
    StatusLine = {
      overwrite = true,
      fg = color.gray8,
      bg = color.gray2,
    },
    ColorColumn = {
      overwrite = true,
      bg = color.gray2,
    },
    -- inactive status line
    StatusLineNC = {
      overwrite = true,
      fg = color.gray6,
      bg = color.gray2,
    },
    -- diagnostics
    NormalFloat = {
      overwrite = true,
      bg = "NONE",
    },
    -- buf.hover()
    FloatBorder = {
      overwrite = true,
      bg = "NONE",
    },
    markdownCode = {
      overwrite = true,
      bg = "NONE",
    },
    markdownCodeBlock = {
      overwrite = true,
      bg = "NONE",
    },
    RenderMarkdownCode = {
      overwrite = true,
      bg = "NONE",
    },
    RenderMarkdownCodeInline = {
      overwrite = true,
      fg = color.gray6,
      bg = "NONE",
    },
    RenderMarkdownCodeBorder = {
      overwrite = true,
      bg = "NONE",
    },
    ["@markup.strong"] = {
      overwrite = true,
      fg = color.gray4,
      bold = true,
    },
    ["@markup.italic"] = {
      overwrite = true,
      fg = color.gray4,
      italic = true,
    },
    MatchParen = {
      overwrite = true,
      bg = color.gray3,
    },
    -- modify @keyword's highlights to be bold and italic
    ["@keyword"] = {
      overwrite = false, -- overwrite falsey will extend/update lackluster's defaults (nil also does this)
      bold = true,
      italic = false,
      -- see `:help nvim_set_hl` for all possible keys
    },
    -- overwrite @function to link to @keyword
    ["@function"] = {
      overwrite = true, -- overwrite == true will force overwrite lackluster's default highlights
      link = "@keyword",
    },
    -- Telescope Settings
    TelescopeMatching = {
      overwrite = true, -- force overwrite instead of extending
      bold = false,
      italic = false,
      fg = "#aa6666", -- pick a color you like
    },
    TelescopeNormal = {
      overwrite = true,
      bg = "NONE",
    },
    TelescopeBorder = {
      overwrite = true,
      bg = "NONE",
    },
    TelescopePreviewNormal = {
      overwrite = true,
      bg = "NONE",
    },
    TelescopePreviewBorder = {
      overwrite = true,
      bg = "NONE",
    },
    TelescopePromptNormal = {
      overwrite = true,
      bg = "NONE",
    },
    TelescopePromptBorder = {
      overwrite = true,
      bg = "NONE",
    },
    TelescopeResultsNormal = {
      overwrite = true,
      bg = "NONE",
    },
    TelescopeResultsBorder = {
      overwrite = true,
      bg = "NONE",
    },
  },
  tweak_ui = {
    disable_undercurl = true,
    enable_end_of_buffer = true,
  },
  tweak_syntax = {
    comment = color.gray4, -- or gray5
  },
  tweak_background = {
    normal = 'none',
    menu = 'none',
    popup = 'none',
  },
})
vim.cmd("colorscheme lackluster-dark")

--------------------------------------------------------------------------------
--- Harpoon
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
vim.keymap.set("n", "<A-m>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<A-n>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<A-e>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<A-i>", function() ui.nav_file(4) end)

--------------------------------------------------------------------------------
--- Markdown
require("render-markdown").setup({
  completions = { lsp = { enabled = true } },
  heading = {
    icons = { '󰼏 ', '󰎨 ' },
    backgrounds = {},
  },
  code = {
    highlight_border = false,
    width = 'block',
    -- min_width = 80,
  },
  overrides = {
    buftype = {
      nofile = {
        code = {
          highlight = 'NormalFloat',
          highlight_inline = 'NormalFloat',
          highlight_border = 'NormalFloat',
          language_border = '',
        },
      },
    },
  },
})

vim.schedule(function()
  vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { fg = color.gray6, bg = "NONE" })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeBorder", { bg = "NONE" })
end)

--------------------------------------------------------------------------------
--- Luasnip
require("luasnip").setup({
  keep_roots = true,
  link_roots = true,
  link_children = true,
  exit_roots = false,
  -- update_events = { "TextChanged", "TextChangedI" },
  update_events = "InsertLeave",
})
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" })

local ls = require("luasnip")

vim.keymap.set({ "i", "s" }, "<C-j>", function() ls.jump(1) end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-k>", function() ls.jump(-1) end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-n>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-p>", function()
  if ls.choice_active() then
    ls.change_choice(-1)
  end
end, { silent = true })

--------------------------------------------------------------------------------
--- Blinkcmp
require("blink.cmp").setup({
  snippets = {
    preset = "luasnip",
  },
  sources = {
    default = { 'snippets', 'lsp', 'path', 'buffer' },
  },
  keymap = {
    preset = "default",
    ["<C-s>"] = { "show_signature", "hide_signature", "fallback" },
    ["<C-k>"] = false,
  },
  signature = {
    enabled = true,
    trigger = {
      enabled = false,
    },
  },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 500 },
    menu = {
      auto_show = true,
      draw = {
        treesitter = { "lsp" },
        columns = { { "label", "label_description", gap = 1 }, { "kind" } },
      },
    },
  },
})

--------------------------------------------------------------------------------
--- Oil
require("oil").setup({
  default_file_explorer = true,
  keymaps = {
    ["<C-c>"] = false,
  },
  view_options = {
    show_hidden = true,
  },
})

vim.keymap.set("n", "<leader>nw", "<CMD>Oil<CR>", { desc = "Open parent directory" })

--------------------------------------------------------------------------------
--- Copilot
vim.g.copilot_enabled = 0

--------------------------------------------------------------------------------
