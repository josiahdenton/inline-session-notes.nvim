local M = {}

--- @class isn.Config
--- @field float ?isn.FloatOpts float options
--- @field default_hl ?string default hl group to use for inline notes

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
}

--- @param config isn.Config
M.setup = function(config)
	if config.float then
		opts.float.width = config.float.width or opts.float.width
		opts.float.height = config.float.height or opts.float.height
	end

	if config.default_hl then
		opts.default_hl = config.default_hl
	end
end

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
		title = title,
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

--- @type table<integer,string[]>
local extmarks = {
	-- id: content
}

--- @param bufnr integer which buffer to draw on
--- @param line_nr integer where in the buffer to draw
--- @param note string[]
local draw_note = function(bufnr, line_nr, note)
	if #note == 0 then
		return
	end

	-- local header = note[1]
	local lines = vim.iter(note)
		:map(function(line)
			return { { line, "TodoFgNOTE" } }
		end)
		:totable()
	local id =
		vim.api.nvim_buf_set_extmark(bufnr, vim.api.nvim_create_namespace("inline-session-notes"), line_nr - 1, 0, {
			virt_lines_above = true,
			-- virt_text = { { header, "TodoFgNOTE" } },
			virt_lines = lines,
			virt_text_pos = "eol",
		})

	extmarks[id] = note
end

--- @param action "add"|"edit"
--- @param content ?string[]
local use_note_buffer = function(action, content)
	local cur_bufnr = vim.api.nvim_get_current_buf()
	local line_nr = vim.fn.getpos(".")[2]
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
		draw_note(cur_bufnr, line_nr, lines)
	end, { desc = "inline-session-notes: save note", buffer = bufnr })

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_buf_is_valid(bufnr) then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
	end, { desc = "inline-session-notes: close notes buffer", buffer = bufnr })
end

M.add = function()
	use_note_buffer("add")
end

M.add()

local lookup = function(tbl, lines)
	for id, content in pairs(tbl) do
		local matching = true
		for i, _ in ipairs(content) do
			if content[i] ~= lines[i] then
				matching = false
				break
			end
		end

		if matching then
			return id
		end
	end
	return -1
end

M.edit = function()
	local cursor_pos = vim.fn.getpos(".")[2]
	local bufnr = vim.api.nvim_get_current_buf()
	local ids = vim.api.nvim_buf_get_extmarks(
		bufnr,
		vim.api.nvim_create_namespace("inline-session-notes"),
		cursor_pos - 1,
		cursor_pos - 1,
		{}
	)
	if #ids == 0 then
		vim.notify("no inline-note found", vim.log.levels.ERROR, {})
	end

	local mark = ids[1]
	local details = mark[3]
	if details then
		-- local lines = { details.virt_text[1][1] }
        local lines = {}
		for _, vtline in ipairs(details.virt_lines) do
			table.insert(lines, vtline[1][1])
		end
		local ext_id = lookup(extmarks, lines)
		if vim.api.nvim_buf_del_extmark(bufnr, vim.api.nvim_create_namespace("inline-session-notes"), ext_id) then
			use_note_buffer("edit", lines)
		else
			vim.notify("failed to edit inline-note, could not remove old extmark", vim.log.levels.ERROR, {})
		end
	else
		vim.notify("failed to get inline-note details", vim.log.levels.ERROR, {})
	end
end

return M
