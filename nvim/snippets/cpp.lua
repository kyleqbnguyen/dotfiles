local ls     = require("luasnip")
local s      = ls.snippet
local t      = ls.text_node
local i      = ls.insert_node
local f      = ls.function_node
local extras = require("luasnip.extras")
local rep    = extras.rep

local function header_guard()
  local filename = vim.fn.expand("%:t")
  return filename
      :upper()
      :gsub("%.", "_")
      :gsub("[^A-Z0-9_]", "_")
end

local function namespace_comment(args)
  local name = args[1][1]
  if name == nil or name == "" then
    return "anonymous namespace"
  end
  return "namespace " .. name
end

return {
  s("hg", {
    t("#ifndef "), f(header_guard, {}), t({ "", "#define " }),
    f(header_guard, {}), t({ "", "", "" }),
    i(0),
    t({ "", "", "#endif // " }),
    f(header_guard, {}),
  }),
  s("ns", {
    t("namespace "),
    i(1),
    t({ "{", "", "" }),
    i(2),
    t({ "", "", "} // " }),
    f(namespace_comment, {1}),
  }),
}
