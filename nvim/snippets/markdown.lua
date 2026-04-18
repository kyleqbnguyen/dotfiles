local ls = require("luasnip")
local s  = ls.snippet
local i  = ls.insert_node
local c  = ls.choice_node
local d  = ls.dynamic_node
local t  = ls.text_node
local f  = ls.function_node
local sn = ls.snippet_node
local r  = ls.restore_node

local function currentDate()
  return os.date("%m-%d-%Y")
end

-- ---
-- pattern: "[[Arrays and Hashing]]"
-- problem: "[217. Contains Duplicates](https://leetcode.com/problems/contains-duplicate/description/)"
-- confidence: Amazing
-- tags: [easy, "unordered_set", leetcode]
-- date: 04-17-2026
-- ---

local function leetcodeBody()
  return sn(nil, {
    t('problem: "['),
    r(1, "leetcode_number"),
    t(". "),
    r(2, "leetcode_name", i(nil, "name")),
    t("]("),
    r(6, "leetcode_link", i(nil, "link")),
    t({ ')"', 'section: "[' }),
    r(3, "leetcode_section", i(nil)),
    t("]("),
    t('https://neetcode.io/roadmap)"'),
    t({ "", "confidence: " }),
    c(4, {
      t("Bad"),
      t("Mid"),
      t("Good"),
      t("Perfect"),
    }),
    t({ "", "tags: [" }),
    i(5),
    t({ "]", "date: " }),
    f(currentDate, {}),
  })
end

local function cppBody()
  return sn(nil, {
    t("source: "),
    i(1),
    t({ "", "tags: [" }),
    i(2),
    t("]"),
  })
end

return {
  s("frontmatter", {
    t({ "---", "class: " }),
    c(1, {
      t("\"[[Leetcode]]\""),
      t("\"[[C++]]\""),
    }),
    t({ "", "" }),
    d(2, function(args)
      if args[1][1] == "\"[[C++]]\"" then
        return cppBody()
      end

      return leetcodeBody()
    end, { 1 }),
    t({ "", "---" }),
  }),
}
