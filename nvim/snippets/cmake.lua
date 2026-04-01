local ls  = require("luasnip")
local s   = ls.snippet
local i   = ls.insert_node
local t   = ls.text_node
local c   = ls.choice_node
local d   = ls.dynamic_node
local sn  = ls.snippet_node
local rep = require("luasnip.extras").rep

local function make_standard_block(lang)
  local prefix = (lang == "C") and "C" or "CXX"
  local standards = (lang == "C")
      and { t("17"), t("11") }
      or { t("20"), t("23"), t("17") }

  return sn(nil, {
    t("set(CMAKE_" .. prefix .. "_STANDARD "),
    c(1, standards),
    t({
      ")",
      "set(CMAKE_" .. prefix .. "_STANDARD_REQUIRED ON)",
      "set(CMAKE_" .. prefix .. "_EXTENSIONS OFF)",
    }),
  })
end

local function make_exe_block(lang)
  local ext = (lang == "C") and "c" or "cpp"

  return sn(nil, {
    t({ "add_executable(${PROJECT_NAME} src/" }),
    i(1, "main." .. ext),
    t({
      ")",
      "",
      "target_include_directories(${PROJECT_NAME}",
      "                           PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)",
    }),
  })
end

local function make_lib_block(lang)
  local ext = (lang == "C") and "c" or "cpp"

  return sn(nil, {
    t({ "add_library(${PROJECT_NAME} src/" }),
    i(1, "file." .. ext),
    t({
      ")",
      "",
      "target_include_directories(${PROJECT_NAME}",
      "                           PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)",
    }),
  })
end

local function make_gtest_empty_block()
  return sn(nil, {
    t({
      "include(FetchContent)",
      "FetchContent_Declare(",
      "  googletest",
      "  GIT_REPOSITORY https://github.com/google/googletest.git",
      "  GIT_TAG ",
    }),
    i(1, "v1.14.0"),
    t({
      "",
      ")",
      "FetchContent_MakeAvailable(googletest)",
      "",
      "add_library(${PROJECT_NAME} INTERFACE)",
      "",
      "target_include_directories(${PROJECT_NAME}",
      "                           INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)",
      "",
      "enable_testing()",
      "add_subdirectory(tests)",
    }),
  })
end

local function make_gtest_block(lang)
  local ext = (lang == "C") and "c" or "cpp"

  return sn(nil, {
    t({
      "include(FetchContent)",
      "FetchContent_Declare(",
      "  googletest",
      "  GIT_REPOSITORY https://github.com/google/googletest.git",
      "  GIT_TAG ",
    }),
    i(1, "v1.14.0"),
    t({
      "",
      ")",
      "FetchContent_MakeAvailable(googletest)",
      "",
      "add_library(${PROJECT_NAME} src/",
    }),
    i(2, "file." .. ext),
    t({
      ")",
      "",
      "target_include_directories(${PROJECT_NAME}",
      "                           PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)",
      "",
      "enable_testing()",
      "add_subdirectory(tests)",
    }),
  })
end

return {
  --- MAIN
  ------------------------------------------------------------------------------
  s("cm", {
    t("cmake_minimum_required(VERSION "),
    i(1, "3.20"),
    t({ ")", "", "project(", "" }),
    t("  "),
    i(2, "name"),
    t({ "", "  VERSION " }),
    i(3, "0.1.0"),
    t({ "", "  LANGUAGES " }),
    c(4, { t("CXX"), t("C") }),
    t({ ")", "", "" }),

    d(5, function(args)
      return make_standard_block(args[1][1])
    end, { 4 }),

    t({
      "",
      "",
      "set(CMAKE_EXPORT_COMPILE_COMMANDS ON)",
      "",
      "add_compile_options(-Wall -Wextra -Wpedantic)",
      "",
      ""
    }),

    t("# "),
    c(6, {
      t("exe"),
      t("lib"),
      t("gtest"),
      t("gtest-empty"),
    }),

    t({ "", "" }),

    d(7, function(args)
      local lang = args[1][1]
      local mode = args[2][1]

      if mode == "exe" then
        return make_exe_block(lang)
      elseif mode == "lib" then
        return make_lib_block(lang)
      elseif mode == "gtest-empty" then
        return make_gtest_empty_block()
      else
        return make_gtest_block(lang)
      end
    end, { 4, 6 }),
  }),

  --- SMOKE
  ------------------------------------------------------------------------------
  s("test", {
    t("add_executable("),
    i(1, "${PROJECT_NAME}_tests"),
    t(" "),
    i(2, "smoke_test.cpp"),
    t({
      ")",
      "",
      "target_link_libraries(",
    }),
    rep(1),
    t(" PRIVATE ${PROJECT_NAME}"),
    t({
      "",
      "                                                    GTest::gtest_main)",
      "",
      "include(GoogleTest)",
      "gtest_discover_tests(",
    }),
    rep(1),
    t(")"),
  }),
}
