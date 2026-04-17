local color = require("lackluster").color

require("render-markdown").setup({
  completions = { lsp = { enabled = true } },
  heading = {
    icons = { "󰼏 ", "󰎨 " },
    backgrounds = {},
  },
  code = {
    highlight_border = false,
    width = "block",
    style = "normal",
  },
  overrides = {
    buftype = {
      nofile = {
        code = {
          highlight = "NormalFloat",
          highlight_inline = "NormalFloat",
          highlight_border = "NormalFloat",
          language_border = "",
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
