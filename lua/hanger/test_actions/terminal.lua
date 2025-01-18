local M = {}

local use_zellij = true

function M.run_in_terminal(cmd)
    local starting_win = vim.api.nvim_get_current_win()

    if use_zellij then
        -- Execute the Zellij command
        local zellij_cmd = "zellij action new-pane -f -- " .. cmd
        vim.fn.system(zellij_cmd)

        -- -- Return to the original window after execution
        -- if vim.api.nvim_win_is_valid(starting_win) then
        --     vim.api.nvim_set_current_win(starting_win)
        -- end
        return
    end

    vim.cmd("split")
    -- vim.cmd("term " .. cmd)
    vim.cmd("term echo '" .. cmd .. "\\n' && " .. cmd)
    vim.cmd("resize | wincmd J")

    -- Get the terminal window and buffer
    local term_win = vim.api.nvim_get_current_win()

    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(term_win),
        callback = function()
            -- Check if our original window still exists
            if vim.api.nvim_win_is_valid(starting_win) then
                vim.api.nvim_set_current_win(starting_win)
            end
        end,
        once = true
    })
end

return M
