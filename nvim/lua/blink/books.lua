local source = {}

local default_opts = {
  root = vim.fn.expand("~/vault/sources"),
  exclude = {
    plan = true,
  },
}

local cached_items = nil

local function is_book_file(name)
  local ext = name:match("%.([^.]+)$")
  if not ext then
    return false
  end

  ext = ext:lower()
  return ext == "pdf" or ext == "epub" or ext == "mobi" or ext == "md"
end

local function normalize_name(name)
  return (name:gsub("%.[^.]+$", ""))
end

local function on_source_line(ctx)
  if vim.bo[ctx.bufnr].filetype ~= "markdown" then
    return false
  end

  local before_cursor = ctx.line:sub(1, ctx.cursor[2])
  return before_cursor:match("^source:%s*.*$") ~= nil
end

local function build_item(name, ctx)
  local prefix = ctx.line:match("^(source:%s*)") or "source: "
  local value_start = #prefix

  return {
    label = name,
    insertText = name,
    filterText = name,
    kind = require("blink.cmp.types").CompletionItemKind.Reference,
    textEdit = {
      newText = name,
      range = {
        start = { line = ctx.cursor[1] - 1, character = value_start },
        ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
      },
    },
  }
end

local function scan_books(root, exclude)
  local seen = {}
  local names = {}

  for entry, kind in vim.fs.dir(root) do
    local name = nil

    if kind == "directory" then
      name = entry
    elseif kind == "file" and is_book_file(entry) then
      name = normalize_name(entry)
    end

    if name and not exclude[name:lower()] and not seen[name] then
      seen[name] = true
      names[#names + 1] = name
    end
  end

  table.sort(names, function(a, b)
    return a:lower() < b:lower()
  end)

  return names
end

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  return self
end

function source:enabled()
  if vim.bo.filetype ~= "markdown" then
    return false
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line():sub(1, cursor[2])
  return line:match("^source:%s*.*$") ~= nil
end

function source:get_completions(ctx, callback)
  if not on_source_line(ctx) then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  if cached_items == nil then
    local ok, names = pcall(scan_books, self.opts.root, self.opts.exclude)
    cached_items = ok and names or {}
  end

  local items = {}
  for _, name in ipairs(cached_items) do
    items[#items + 1] = build_item(name, ctx)
  end

  callback({
    items = items,
    is_incomplete_forward = false,
    is_incomplete_backward = false,
  })
end

return source
