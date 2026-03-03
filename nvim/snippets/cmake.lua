local ls = require("luasnip")
local s  = ls.snippet
local i  = ls.insert_node
local t  = ls.text_node
local c  = ls.choice_node
local d  = ls.dynamic_node
local sn = ls.snippet_node

return {
  s("cm", {
    t("cmake_minimum_required(VERSION "),
    i(1, "4.2.3"),
    t({ ")", "", "project(", "" }),
    t("  "),
    i(2, "name"),
    t({ "", "  VERSION " }),
    i(3, "0.1.0"),

    t({ "", "  LANGUAGES " }),
    c(4, { t("CXX"), t("C") }),
    t({ ")", "", "" }),

    d(5, function(args)
      local lang = args[1][1]

      local prefix = (lang == "C") and "C" or "CXX"
      local standards = (lang == "C") and { t("17"), t("11") } or { t("20"), t("23"), t("17") }

      return sn(nil, {
        t("set(CMAKE_" .. prefix .. "_STANDARD "),
        c(1, standards),
        t({
          ")",
          "set(CMAKE_" .. prefix .. "_STANDARD_REQUIRED ON)",
          "set(CMAKE_" .. prefix .. "_EXTENSIONS OFF)",
        }),
      })
    end, { 4 }),

    t({ "", "", "set(CMAKE_EXPORT_COMPILE_COMMANDS ON)", "", "" }),

    d(6, function(args)
      local lang = args[1][1]
      local ext = (lang == "C") and "c" or "cpp"

      return sn(nil, {
        t({ "add_executable(", "  ${PROJECT_NAME}", "  src/main." .. ext .. ")", })
      })
    end, { 4 }),
  }),
}
