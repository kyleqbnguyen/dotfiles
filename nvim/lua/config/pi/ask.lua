local pi = require("pi")

local M = {}

local prompt_buf = nil
local prompt_win = nil
local response_buf = nil
local response_win = nil
local pending_context = nil
local submitting = false

local separator = "════════════════════════════════════════════════════════════════════════════════════════════════════"

local function valid_buf(buf)
	return buf and vim.api.nvim_buf_is_valid(buf)
end

local function valid_win(win)
	return win and vim.api.nvim_win_is_valid(win)
end

local function notify_raw(value)
	vim.notify(vim.inspect(value), vim.log.levels.ERROR)
end

local function ensure_prompt_buffer()
	if valid_buf(prompt_buf) then
		return prompt_buf
	end

	prompt_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[prompt_buf].buftype = "acwrite"
	vim.bo[prompt_buf].bufhidden = "hide"
	vim.bo[prompt_buf].swapfile = false
	vim.bo[prompt_buf].modifiable = true
	vim.bo[prompt_buf].readonly = false
	vim.bo[prompt_buf].filetype = "markdown"
	vim.api.nvim_buf_set_name(prompt_buf, "PiAsk Prompt")

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = prompt_buf,
		callback = function()
			vim.bo[prompt_buf].modified = false
		end,
	})

	vim.api.nvim_create_autocmd("QuitPre", {
		buffer = prompt_buf,
		callback = function()
			if vim.api.nvim_get_current_buf() == prompt_buf then
				M.submit()
			end
		end,
	})

	return prompt_buf
end

local function open_prompt(context)
	if context ~= nil then
		pending_context = context
	end
	local buf = ensure_prompt_buffer()

	if valid_win(prompt_win) then
		vim.api.nvim_set_current_win(prompt_win)
	else
		local width = 80
		local height = math.floor(vim.o.lines * 0.35)
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		prompt_win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			row = row,
			col = col,
			width = width,
			height = height,
			border = "rounded",
			title = " PiAsk ",
			title_pos = "center",
		})
	end

	vim.wo[prompt_win].number = true
	vim.wo[prompt_win].relativenumber = false
	vim.wo[prompt_win].signcolumn = "no"
	vim.bo[buf].modifiable = true
	vim.bo[buf].readonly = false
	vim.cmd("stopinsert")
end

local function ensure_response_buffer()
	if valid_buf(response_buf) then
		return response_buf
	end

	response_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[response_buf].buftype = "nofile"
	vim.bo[response_buf].bufhidden = "hide"
	vim.bo[response_buf].swapfile = false
	vim.bo[response_buf].filetype = "markdown"
	vim.bo[response_buf].readonly = true
	vim.bo[response_buf].modifiable = false
	vim.api.nvim_buf_set_name(response_buf, "PiAsk Response")

	return response_buf
end

local function with_response_writable(fn)
	local buf = ensure_response_buffer()
	vim.bo[buf].readonly = false
	vim.bo[buf].modifiable = true
	fn(buf)
	vim.bo[buf].modified = false
	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true
end

local function append_text(text)
	if type(text) ~= "string" or text == "" then
		return
	end

	vim.schedule(function()
		with_response_writable(function(buf)
			local parts = vim.split(text, "\n", { plain = true })
			local last = vim.api.nvim_buf_line_count(buf) - 1
			local line = vim.api.nvim_buf_get_lines(buf, last, last + 1, false)[1] or ""

			vim.api.nvim_buf_set_lines(buf, last, last + 1, false, { line .. parts[1] })
			if #parts > 1 then
				vim.api.nvim_buf_set_lines(buf, last + 1, last + 1, false, vim.list_slice(parts, 2))
			end
		end)
	end)
end

local function clear_prompt()
	vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "" })
	vim.bo[prompt_buf].modified = false
end

local function append_separator()
	vim.schedule(function()
		with_response_writable(function(buf)
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			if #lines == 1 and lines[1] == "" then
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, { separator, "" })
			else
				vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", "", separator, "" })
			end
		end)
	end)
end

local function window_count()
	return #vim.api.nvim_tabpage_list_wins(0)
end

local function ensure_response_window()
	local buf = ensure_response_buffer()

	if valid_win(response_win) then
		vim.api.nvim_win_set_buf(response_win, buf)
		return response_win
	end

	local current = vim.api.nvim_get_current_win()
	vim.cmd("botright vsplit")
	response_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(response_win, buf)
	vim.api.nvim_win_set_width(response_win, math.floor(vim.o.columns / 2))
	vim.api.nvim_set_current_win(current)

	return response_win
end

local function response_window_open()
	return valid_win(response_win) and vim.api.nvim_win_get_buf(response_win) == response_buf
end

local function close_response_window()
	if response_window_open() then
		if window_count() == 1 then
			return false
		end
		vim.api.nvim_win_close(response_win, false)
	end
	response_win = nil
	return true
end

local function format_diagnostic(diagnostic)
	local lines = {
		string.format(
			"- %s at %d:%d-%d:%d",
			diagnostic.severity_label,
			diagnostic.start_line,
			diagnostic.start_col,
			diagnostic.finish_line,
			diagnostic.finish_col
		),
	}

	if diagnostic.source and diagnostic.source ~= "" then
		table.insert(lines, "  Source: " .. diagnostic.source)
	end
	if diagnostic.code and diagnostic.code ~= "" then
		table.insert(lines, "  Code: " .. diagnostic.code)
	end
	table.insert(lines, "  Message: " .. diagnostic.message)

	return table.concat(lines, "\n")
end

local function format_context(ctx)
	if ctx.kind == "file" then
		return table.concat({
			"Context: " .. ctx.file,
			"",
		}, "\n")
	end

	if ctx.kind == "diagnostic" then
		local lines = {
			"Context: diagnostics at " .. ctx.file .. ":" .. ctx.range,
			"",
			"Diagnostics:",
			table.concat(vim.tbl_map(format_diagnostic, ctx.diagnostics), "\n"),
		}

		if ctx.text and ctx.text ~= "" then
			local fence = "```" .. (ctx.filetype or "")
			vim.list_extend(lines, {
				"",
				"Code:",
				fence,
				ctx.text,
				"```",
			})
		end

		table.insert(lines, "")
		return table.concat(lines, "\n")
	end

	local start_line = ctx.display_range.start.line
	local finish_line = ctx.display_range.finish.line
	local range = tostring(start_line)
	if start_line ~= finish_line then
		range = range .. "-" .. tostring(finish_line)
	end

	local fence = "```" .. (ctx.filetype or "")
	return table.concat({
		"Context: " .. ctx.file .. ":" .. range,
		"",
		fence,
		ctx.text,
		"```",
		"",
	}, "\n")
end

local function prompt_text()
	return table.concat(vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false), "\n")
end

local function build_message()
	local prompt = prompt_text()
	if pending_context then
		return format_context(pending_context) .. prompt
	end
	return prompt
end

local function format_response()
	vim.schedule(function()
		with_response_writable(function(buf)
			require("conform").format({ bufnr = buf, async = false, lsp_format = "fallback" })
		end)
	end)
end

local function close_prompt_window()
	if valid_win(prompt_win) then
		vim.api.nvim_win_close(prompt_win, false)
		prompt_win = nil
	end
end

local function send_message(message, streaming_behavior)
	pending_context = nil
	vim.bo[prompt_buf].modified = false
	clear_prompt()

	vim.schedule(function()
		ensure_response_window()
		append_separator()

		local opts = {
			message = message,
			on_event = function(event)
				if event.type == "agent_end" then
					format_response()
					return
				end

				local text = pi.rpc.extract_text_delta(event)
				if text then
					append_text(text)
				end
			end,
			on_error = function(error)
				notify_raw(error)
			end,
		}

		if streaming_behavior then
			opts.streaming_behavior = streaming_behavior
		end

		local _, err = pi.prompts.send(opts)

		if err then
			notify_raw(err)
		end

		submitting = false
	end)
end

local function choose_streaming_behavior(message)
	local choices = {
		{ value = "followUp", label = "followUp — send after current response" },
		{ value = "steer", label = "steer — guide current response" },
	}

	vim.ui.select(choices, {
		prompt = "Pi is already streaming",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice then
			submitting = false
			return
		end

		send_message(message, choice.value)
	end)
end

local function severity_label(severity)
	local names = vim.diagnostic.severity
	if severity == names.ERROR then
		return "ERROR"
	elseif severity == names.WARN then
		return "WARN"
	elseif severity == names.INFO then
		return "INFO"
	elseif severity == names.HINT then
		return "HINT"
	end
	return "UNKNOWN"
end

local function diagnostic_sort(a, b)
	local a_severity = a.severity or 999
	local b_severity = b.severity or 999
	if a_severity ~= b_severity then
		return a_severity < b_severity
	end
	if (a.lnum or 0) ~= (b.lnum or 0) then
		return (a.lnum or 0) < (b.lnum or 0)
	end
	return (a.col or 0) < (b.col or 0)
end

local function diagnostic_contains_cursor(diagnostic, lnum, col)
	local start_lnum = diagnostic.lnum or lnum
	local finish_lnum = diagnostic.end_lnum or start_lnum
	local start_col = diagnostic.col or 0
	local finish_col = diagnostic.end_col or start_col

	if lnum < start_lnum or lnum > finish_lnum then
		return false
	end
	if lnum == start_lnum and col < start_col then
		return false
	end
	if lnum == finish_lnum and finish_col > start_col and col >= finish_col then
		return false
	end
	return true
end

local function range_before_or_equal(a_line, a_col, b_line, b_col)
	return a_line < b_line or (a_line == b_line and a_col <= b_col)
end

local function diagnostic_intersects_range(diagnostic, range)
	local start_lnum = diagnostic.lnum or range.start.line
	local finish_lnum = diagnostic.end_lnum or start_lnum
	local start_col = diagnostic.col or 0
	local finish_col = diagnostic.end_col or start_col + 1

	return not (
		range_before_or_equal(finish_lnum, finish_col, range.start.line, range.start.col)
		or range_before_or_equal(range.finish.line, range.finish.col, start_lnum, start_col)
	)
end

local function diagnostic_code(code)
	if code == nil then
		return nil
	end
	if type(code) == "string" or type(code) == "number" then
		return tostring(code)
	end
	return vim.inspect(code)
end

local function normalize_diagnostic(diagnostic, fallback_lnum)
	return {
		severity_label = severity_label(diagnostic.severity),
		start_line = (diagnostic.lnum or fallback_lnum or 0) + 1,
		start_col = (diagnostic.col or 0) + 1,
		finish_line = (diagnostic.end_lnum or diagnostic.lnum or fallback_lnum or 0) + 1,
		finish_col = (diagnostic.end_col or diagnostic.col or 0) + 1,
		source = diagnostic.source,
		code = diagnostic_code(diagnostic.code),
		message = diagnostic.message or "",
	}
end

local function diagnostic_range(selected, fallback_lnum)
	local start_lnum = fallback_lnum or 0
	local finish_lnum = fallback_lnum or 0
	for _, diagnostic in ipairs(selected) do
		start_lnum = math.min(start_lnum, diagnostic.lnum or fallback_lnum or 0)
		finish_lnum = math.max(finish_lnum, diagnostic.end_lnum or diagnostic.lnum or fallback_lnum or 0)
	end

	local range = tostring(start_lnum + 1)
	if start_lnum ~= finish_lnum then
		range = range .. "-" .. tostring(finish_lnum + 1)
	end
	return range, start_lnum, finish_lnum
end

local function make_diagnostic_context(bufnr, selected, range, text)
	table.sort(selected, diagnostic_sort)
	return {
		kind = "diagnostic",
		file = vim.api.nvim_buf_get_name(bufnr),
		filetype = vim.bo[bufnr].filetype,
		range = range,
		text = text,
		diagnostics = vim.tbl_map(function(diagnostic)
			return normalize_diagnostic(diagnostic)
		end, selected),
	}
end

local function diagnostic_context()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local lnum = cursor[1] - 1
	local col = cursor[2]
	local diagnostics = vim.diagnostic.get(bufnr)
	local selected = vim.tbl_filter(function(diagnostic)
		return diagnostic_contains_cursor(diagnostic, lnum, col)
	end, diagnostics)

	if #selected == 0 then
		selected = vim.diagnostic.get(bufnr, { lnum = lnum })
	end
	if #selected == 0 then
		return nil
	end

	local range, start_lnum, finish_lnum = diagnostic_range(selected, lnum)
	local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, start_lnum, finish_lnum + 1, false), "\n")
	return make_diagnostic_context(bufnr, selected, range, text)
end

local function selection_diagnostic_context()
	local selection, err = pi.context.selection({ source = "active" })
	if err then
		return nil, err
	end

	local selected = vim.tbl_filter(function(diagnostic)
		return diagnostic_intersects_range(diagnostic, selection.range)
	end, vim.diagnostic.get(selection.bufnr))
	if #selected == 0 then
		return nil, nil
	end

	local start_line = selection.display_range.start.line
	local finish_line = selection.display_range.finish.line
	local range = tostring(start_line)
	if start_line ~= finish_line then
		range = range .. "-" .. tostring(finish_line)
	end

	return make_diagnostic_context(selection.bufnr, selected, range, selection.text)
end

local function buffer_diagnostic_context()
	local bufnr = vim.api.nvim_get_current_buf()
	local selected = vim.diagnostic.get(bufnr)
	if #selected == 0 then
		return nil
	end
	return make_diagnostic_context(bufnr, selected, "buffer", nil)
end

function M.submit()
	if submitting then
		return
	end
	submitting = true

	local message = build_message()
	local prompt = prompt_text()
	local snapshot = pi.state.get()

	close_prompt_window()

	if prompt == "" then
		vim.notify("PiAsk requires a prompt.", vim.log.levels.WARN)
		submitting = false
		return
	end

	if not snapshot.running then
		vim.notify("Pi RPC is not running. Start one with :PiStart or :PiAttachSession.", vim.log.levels.WARN)
		submitting = false
		return
	end

	if snapshot.is_streaming then
		choose_streaming_behavior(message)
		return
	end

	send_message(message)
end

function M.ask_with_selection()
	local ctx, err = pi.context.selection({ source = "active" })
	if err then
		vim.notify(err.message or tostring(err), vim.log.levels.WARN, { title = "PiAsk" })
		return
	end
	open_prompt(ctx)
end

function M.ask_file()
	open_prompt({
		kind = "file",
		file = vim.api.nvim_buf_get_name(0),
	})
end

function M.ask_diagnostic()
	local ctx = diagnostic_context()
	if not ctx then
		vim.notify("PiAskDiagnostic: no diagnostics at cursor", vim.log.levels.WARN, { title = "PiAsk" })
		return
	end
	open_prompt(ctx)
end

function M.ask_selection_diagnostics()
	local ctx, err = selection_diagnostic_context()
	if err then
		vim.notify(err.message or tostring(err), vim.log.levels.WARN, { title = "PiAsk" })
		return
	end
	if not ctx then
		vim.notify("PiAskDiagnostic: no diagnostics in selection", vim.log.levels.WARN, { title = "PiAsk" })
		return
	end
	open_prompt(ctx)
end

function M.ask_buffer_diagnostics()
	local ctx = buffer_diagnostic_context()
	if not ctx then
		vim.notify("PiAskBufferDiagnostics: no diagnostics in buffer", vim.log.levels.WARN, { title = "PiAsk" })
		return
	end
	open_prompt(ctx)
end

function M.clear_context()
	pending_context = nil
	vim.notify("PiAsk context cleared", vim.log.levels.INFO)
end

function M.open_response()
	ensure_response_window()
end

function M.toggle_response()
	if response_window_open() then
		close_response_window()
		return
	end

	response_win = nil
	ensure_response_window()
end

function M.toggle_prompt()
	if valid_win(prompt_win) then
		vim.api.nvim_win_close(prompt_win, false)
		prompt_win = nil
		return
	end

	open_prompt(nil)
end

function M.setup()
	vim.api.nvim_create_user_command("PiAsk", function()
		M.toggle_prompt()
	end, {})
	vim.api.nvim_create_user_command("PiAskFile", function()
		M.ask_file()
	end, {})
	vim.api.nvim_create_user_command("PiAskDiagnostic", function()
		M.ask_diagnostic()
	end, {})
	vim.api.nvim_create_user_command("PiAskBufferDiagnostics", function()
		M.ask_buffer_diagnostics()
	end, {})
	vim.api.nvim_create_user_command("PiAskClearContext", function()
		M.clear_context()
	end, {})
	vim.api.nvim_create_user_command("PiAskResponse", function()
		M.toggle_response()
	end, {})

	vim.keymap.set("n", "<leader>pa", M.toggle_prompt, { silent = true, desc = "PiAsk" })
	vim.keymap.set("x", "<leader>pa", M.ask_with_selection, { silent = true, desc = "PiAsk selection" })
	vim.keymap.set("n", "<leader>pf", M.ask_file, { silent = true, desc = "PiAsk file" })
	vim.keymap.set("n", "<leader>pd", M.ask_diagnostic, { silent = true, desc = "PiAsk diagnostic" })
	vim.keymap.set("x", "<leader>pd", M.ask_selection_diagnostics, { silent = true, desc = "PiAsk selection diagnostics" })
	vim.keymap.set("n", "<leader>pD", M.ask_buffer_diagnostics, { silent = true, desc = "PiAsk buffer diagnostics" })
	vim.keymap.set("n", "<leader>pr", M.toggle_response, { silent = true, desc = "PiAsk response" })
	vim.keymap.set("n", "<leader>cc", M.clear_context, { silent = true, desc = "PiAsk clear context" })
end

return M
