local M = {}

function M.copy_buf_abs_path()
    local bufNum = vim.api.nvim_get_current_buf()
    local bufPath = vim.api.nvim_buf_get_name(bufNum)
    vim.fn.setreg('+', bufPath)
    print("Buffer path copied to clipboard")
end

return M
