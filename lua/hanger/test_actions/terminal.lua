local M = {}
local cmd_cache = nil

local function execute_in_zellij(cmd, config)
    -- Base Zellij command
    local zellij_cmd = "zellij action new-pane"

    -- Add floating option
    if config.floating_pane then
        zellij_cmd = zellij_cmd .. " -f"
    end

    zellij_cmd = zellij_cmd .. " --name " .. vim.fn.shellescape("TEST RUNNER")

    -- Add the actual command to run
    zellij_cmd = zellij_cmd .. " -- " .. cmd

    -- Execute the Zellij command
    vim.fn.system(zellij_cmd)
end

local function execute_in_nvim_term(cmd, _)
    vim.cmd("split")
    vim.cmd("term echo '" .. cmd .. "\\n' && " .. cmd)
    vim.cmd("resize | wincmd J")

    -- Get the terminal window and buffer
    local term_win = vim.api.nvim_get_current_win()

    local starting_win = vim.api.nvim_get_current_win()
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

function M.execute(cmd, config)
    vim.notify(cmd, vim.log.levels.INFO)
    cmd_cache = cmd

    if config.output == "zellij" then
        execute_in_zellij(cmd, config)
        return
    end

    execute_in_nvim_term(cmd, config)
end

function M.execute_cache(config)
    if cmd_cache == nil then
        vim.notify("no tests were run previously", vim.log.levels.INFO)
        return
    end

    M.execute(cmd_cache, config)
end

return M
