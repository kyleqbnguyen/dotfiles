local pi = require("pi")

local M = {}

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "Pi.nvim" })
end

local function notify_error(err)
	if not err then
		return false
	end
	notify(err.message or tostring(err), vim.log.levels.ERROR)
	return true
end

local function attach_session(session)
	local _, err = pi.sessions.attach(session.path, function(response)
		if response.success and not (response.data or {}).cancelled then
			notify("Pi.nvim attached Pi session", vim.log.levels.INFO)
		elseif response.success then
			notify("Pi.nvim session attach cancelled", vim.log.levels.WARN)
		else
			notify(response.error or "Pi.nvim session attach failed", vim.log.levels.ERROR)
		end
	end)

	if not notify_error(err) then
		notify("Pi.nvim session attach requested", vim.log.levels.INFO)
	end
end

function M.sessions(opts)
	opts = opts or {}

	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		notify("telescope.nvim is required for Pi sessions picker", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local themes = require("telescope.themes")

	local sessions, err = pi.sessions.list()
	if notify_error(err) then
		return
	end

	sessions = sessions or {}
	opts = themes.get_dropdown(vim.tbl_deep_extend("force", {
		prompt_title = "Pi Sessions",
		previewer = false,
	}, opts))

	pickers
		.new(opts, {
			finder = finders.new_table({
				results = sessions,
				entry_maker = function(session)
					local display = pi.sessions.format_session(session)
					return {
						value = session,
						display = display,
						ordinal = table.concat({
							session.name or "",
							session.id or "",
							session.cwd or "",
							session.basename or "",
							session.path or "",
							display,
						}, " "),
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					if selection and selection.value then
						attach_session(selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

function M.setup()
	vim.api.nvim_create_user_command("PiSessions", function()
		M.sessions()
	end, { desc = "Pick and attach to a Pi session with Telescope" })

	vim.keymap.set("n", "<leader>ps", M.sessions, { silent = true, desc = "Pi sessions" })
end

return M
