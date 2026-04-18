local _99 = require("99")

_99.setup({
  model = "openai/gpt-5.4-fast",
  tmp_dir = "./.tmp",
})

vim.keymap.set("v", "<leader>c", function()
  _99.visual()
end)

vim.keymap.set("n", "<leader>cx", function()
  _99.stop_all_requests()
end)

vim.keymap.set("n", "<leader>9s", function()
  _99.search()
end)
