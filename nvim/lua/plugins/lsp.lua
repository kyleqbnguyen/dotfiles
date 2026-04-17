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

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "html", "css" },
  callback = function()
    vim.bo.formatprg = "prettier --ignore-path /dev/null --stdin-filepath %"
  end,
})

vim.keymap.set("n", "grd", vim.lsp.buf.definition, { silent = true })
