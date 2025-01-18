local M = {}

function M.get_file_extension()
    local file_ext = vim.fn.expand("%:e")
    if file_ext ~= "go" and file_ext ~= "rs" then
        print("test not configured for '." .. file_ext .. "' extension")
        return
    end

    return file_ext
end

return M
