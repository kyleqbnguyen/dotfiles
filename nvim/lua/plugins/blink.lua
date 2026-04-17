require("blink.cmp").setup({
  snippets = {
    preset = "luasnip",
  },
  sources = {
    default = { "snippets", "lsp", "path", "buffer", "books" },
    providers = {
      books = {
        name = "Books",
        module = "blink.books",
        score_offset = 8,
        opts = {
          root = vim.fn.expand("~/vault/sources"),
          exclude = {
            plan = true,
          },
        },
      },
    },
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
