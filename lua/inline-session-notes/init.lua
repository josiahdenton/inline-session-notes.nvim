local M = {}

local ui = require("inline-session-notes.ui")
local list = require("inline-session-notes.list")
local encoding = require("inline-session-notes.encoding")

--- @class isn.Config
--- @field float ?isn.FloatOpts float options
--- @field default_hl ?string default hl group to use for inline notes
--- @field icon ?string
--- @field border ?boolean

--- @class isn.FloatOpts
--- @field width number >1 for abs size, <=1 for win relative sizing
--- @field height number >1 for abs size, <=1 for win relative sizing

--- @type isn.Config
local opts = {
	float = {
		height = 10,
		width = 50,
	},
	default_hl = "TodoFgNOTE",
	icon = " ",
	border = false,
}

--- @param config ?isn.Config
M.setup = function(config)
	config = config or {}
	if config.float then
		opts.float.width = config.float.width or opts.float.width
		opts.float.height = config.float.height or opts.float.height
	end

	if config.default_hl then
		opts.default_hl = config.default_hl
	end

	if config.icon then
		opts.icon = config.icon
	end

	if config.border ~= nil then
		opts.border = config.border
	end
end

local HELP = ": <enter> - save <q> - quit"

--- @param bufnr integer
--- @param title string
local open_float = function(bufnr, title)
	local win = vim.api.nvim_get_current_win()
	local win_width = vim.api.nvim_win_get_width(win)
	local win_height = vim.api.nvim_win_get_height(win)

	local height = opts.float.height
	local width = opts.float.width

	if opts.float.height <= 1 then
		height = math.floor(win_height * opts.float.height)
	end
	if opts.float.width <= 1 then
		width = math.floor(win_width * opts.float.width)
	end

	local row = (win_height - height) * 0.5
	local col = (win_width - width) * 0.5

	local float_win = vim.api.nvim_open_win(bufnr, true, {
		title = title .. HELP,
		border = "rounded",
		relative = "win",
		win = win,
		row = row,
		col = col,
		height = height,
		width = width,
	})
	return float_win
end

--- @param bufnr integer which buffer to draw on
--- @param line_nr integer where in the buffer to draw
--- @param col_nr integer where in the buffer to draw
--- @param note string[]
local draw_note = function(bufnr, line_nr, col_nr, note)
	if #note == 0 then
		return
	end

	local symbol = opts.icon
	local max_width = list.max(vim.iter(note)
		:map(function(line)
			local len = #(symbol .. line)
			symbol = ""
			return len
		end)
		:totable())
	symbol = opts.icon
	local lines = vim.iter(note)
		:map(function(line)
			local vline
			local offset = encoding.utf8_len(symbol)

			if opts.border then
				vline = {
					{ string.rep(" ", col_nr - 1), "Comment" },
					{ ui.vertical, ui.border_hl },
					{ symbol .. line, opts.default_hl },
					{ string.rep(" ", max_width - #line - offset), "Comment" },
					{ ui.vertical, ui.border_hl },
				}
			else
				vline = {
					{ string.rep(" ", col_nr - 1), "Comment" },
					{ symbol .. line, opts.default_hl },
				}
			end
			symbol = ""
			return vline
		end)
		:totable()
	if opts.border then
		table.insert(lines, 1, {
			{ string.rep(" ", col_nr - 1), "Comment" },
			{ ui.top_left, ui.border_hl },
			{ string.rep(ui.horizontal, max_width), ui.border_hl },
			{ ui.top_right, ui.border_hl },
		})
		table.insert(lines, #lines + 1, {
			{ string.rep(" ", col_nr - 1), "Comment" },
			{ ui.bottom_left, ui.border_hl },
			{ string.rep(ui.horizontal, max_width), ui.border_hl },
			{ ui.bottom_right, ui.border_hl },
		})
	end
	vim.api.nvim_buf_set_extmark(bufnr, vim.api.nvim_create_namespace("inline-session-notes"), line_nr - 1, 0, {
		virt_lines_above = true,
		virt_lines = lines,
	})
end

--- @param action "add"|"edit"
--- @param content ?string[]
--- @param mid ?integer mark id
--- @param ebufnr ?integer
local use_note_buffer = function(action, content, mid, ebufnr)
	local cur_bufnr = vim.api.nvim_get_current_buf()
	local line_nr = vim.fn.getpos(".")[2]
	local col_nr = vim.fn.col(".")
	local bufnr = vim.api.nvim_create_buf(false, true)
	open_float(bufnr, action == "add" and "Add inline-note" or "Edit inline-note")

	if content then
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
	end

	vim.keymap.set("n", "<enter>", function()
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		if vim.api.nvim_buf_is_valid(bufnr) then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
		if mid and ebufnr then
			vim.api.nvim_buf_del_extmark(ebufnr, vim.api.nvim_create_namespace("inline-session-notes"), mid)
		end
		draw_note(cur_bufnr, line_nr, col_nr, lines)
	end, { desc = "inline-session-notes: save note", buffer = bufnr })

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_buf_is_valid(bufnr) then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
	end, { desc = "inline-session-notes: close notes buffer", buffer = bufnr })

	vim.cmd("startinsert!")
end

M.add = function()
	use_note_buffer("add")
end

M.delete = function()
	local cursor_pos = vim.fn.getpos(".")[2]
	local bufnr = vim.api.nvim_get_current_buf()
	local ids = vim.api.nvim_buf_get_extmarks(
		bufnr,
		vim.api.nvim_create_namespace("inline-session-notes"),
		{ cursor_pos - 1, 0 },
		{ cursor_pos, 0 },
		{ details = true }
	)
	if #ids == 0 then
		vim.notify("no inline-note found", vim.log.levels.ERROR, {})
		return
	end

	local mark = ids[1]
	local mid = mark[1]

	if vim.api.nvim_buf_del_extmark(bufnr, vim.api.nvim_create_namespace("inline-session-notes"), mid) then
		vim.notify("deleted note", vim.log.levels.INFO, {})
	else
		vim.notify("failed to remove extmark", vim.log.levels.ERROR, {})
	end
end

--- @param line table<table<string>>
--- @return string text inside the virtual line
local text = function(line)
	for _, vtpair in ipairs(line) do
		if vtpair[2] == opts.default_hl then
			return vtpair[1]
		end
	end
	return ""
end

M.edit = function()
	local cursor_pos = vim.fn.getpos(".")[2]
	local bufnr = vim.api.nvim_get_current_buf()
	local ids = vim.api.nvim_buf_get_extmarks(
		bufnr,
		vim.api.nvim_create_namespace("inline-session-notes"),
		{ cursor_pos - 1, 0 },
		{ cursor_pos, 0 },
		{ details = true }
	)
	if #ids == 0 then
		vim.notify("no inline-note found", vim.log.levels.ERROR, {})
		return
	end

	local mark = ids[1]
	local mid = mark[1]
	local details = mark[4]
	if mid and details then
		local lines = {}
		local vlines = details.virt_lines
		if opts.border then
			vlines = vim.list_slice(vlines, 2, #vlines - 1)
		end
		for i, vline in ipairs(vlines) do
			local content = text(vline)
			local line = vim.trim(content)
			if i == 1 and opts.icon then
				line = string.sub(line, #opts.icon + 1)
			end
			table.insert(lines, line)
		end
		use_note_buffer("edit", lines, mid, bufnr)
	else
		vim.notify("failed to get inline-note details", vim.log.levels.ERROR, {})
	end
end

-- TODO: enhance with getting the column correct? could save markid + col
M.quickfix = function()
	local buffers = vim.api.nvim_list_bufs()
	local qfixlist = {}
	for _, bufnr in ipairs(buffers) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			local marks = vim.api.nvim_buf_get_extmarks(
				bufnr,
				vim.api.nvim_create_namespace("inline-session-notes"),
				{ 0, 0 },
				{ -1, -1 },
				{ details = true }
			)
			for _, mark in ipairs(marks) do
				local row = mark[2]
				local details = mark[4]
				table.insert(qfixlist, {
					bufnr = bufnr,
					lnum = row + 1,
					col = 1,
					text = table.concat(
						vim.iter(details.virt_lines)
							:map(function(vline)
								return text(vline)
							end)
							:totable(),
						"\n"
					),
				})
			end
		end
	end

	vim.fn.setqflist(qfixlist)
	vim.cmd("copen")
end

return M
