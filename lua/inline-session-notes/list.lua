local M = {}

--- @param tbl table<integer>
M.max = function (tbl)
    if #tbl == 0 then
        return 0
    end
    local max = tbl[1]
    for _, v in ipairs(tbl) do
        if v > max then
            max = v
        end
    end
    return max
end

return M
