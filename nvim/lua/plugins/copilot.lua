for _, path in ipairs(vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/opt/copilot.vim", false, true)) do
  vim.opt.runtimepath:remove(path)
end

local function load_copilot()
  if vim.g.loaded_copilot == 1 then
    return
  end

  vim.api.nvim_del_user_command("Copilot")
  vim.cmd.packadd("copilot.vim")
end

vim.api.nvim_create_user_command("Copilot", function(opts)
  load_copilot()

  local command = { "Copilot" }
  if opts.bang then
    command[1] = "Copilot!"
  end
  if opts.args ~= "" then
    table.insert(command, opts.args)
  end

  vim.cmd(table.concat(command, " "))
end, {
  bang = true,
  nargs = "*",
})

vim.g.copilot_enabled = 0
