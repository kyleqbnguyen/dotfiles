local ls     = require("luasnip")
local s      = ls.snippet
local t      = ls.text_node
local i      = ls.insert_node
local f      = ls.function_node

local function header_guard()
  local filename = vim.fn.expand("%:t")
  return filename
      :upper()
      :gsub("%.", "_")
      :gsub("[^A-Z0-9_]", "_")
end

return {
  s("hg", {
    t("#ifndef "), f(header_guard, {}), t({ "", "#define " }),
    f(header_guard, {}), t({ "", "", "" }),
    i(0),
    t({ "", "", "#endif // " }),
    f(header_guard, {}),
  }),
}
