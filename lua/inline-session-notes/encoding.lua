local M = {}

M.utf8_len = function(s)
	local _, count = string.gsub(s, "[^\128-\193]", "")
	return count
end

return M
