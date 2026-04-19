vim.lsp.enable({ "lua_ls", "ts_ls", "eslint", "rust_analyzer", "clangd" })

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
})

vim.keymap.set("n", "<leader>f", function()
  require("conform").format()
end)

vim.keymap.set("n", "grd", vim.lsp.buf.definition, { silent = true })
