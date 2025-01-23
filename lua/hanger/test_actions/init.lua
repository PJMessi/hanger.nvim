local M = {}
local golangpkg = require("hanger.test_actions.go_test_module_extractor")
local rustlangpkg = require("hanger.test_actions.rust_test_module_extractor")
local terminal = require("hanger.test_actions.terminal")
local utils = require("hanger.test_actions.utils")

M.config = {
    output = "term",      -- options: 'term' / 'zellij'
    floating_pane = false, -- only valid for 'zellij' 'output'
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
end

local cmd_cache = nil

function M.run_single_test()
    local cmd = M.get_test_cmd(true)
    if cmd == nil then
        return
    end

    -- Cache the command
    cmd_cache = cmd

    terminal.run_in_terminal(cmd, M.config)
end

function M.run_tests_in_file()
    local cmd = M.get_test_cmd(false)
    if cmd == nil then
        return
    end

    -- Cache the command
    cmd_cache = cmd

    terminal.run_in_terminal(cmd, M.config)
end

function M.rerun_test()
    if cmd_cache == "" or cmd_cache == nil then
        print("you have not ran any tests this session to rerun")
        return
    end

    terminal.run_in_terminal(cmd_cache, M.config)
end

function M.get_test_cmd(is_single)
    local file_ext = utils.get_file_extension()
    if file_ext == "" then
        return
    end

    local cmd = nil

    if file_ext == "go" then
        if is_single then
            cmd = golangpkg.get_single_test_command()
        else
            cmd = golangpkg.get_package_test_command()
        end
    elseif file_ext == "rs" then
        if is_single then
            cmd = rustlangpkg.get_single_test_command()
        else
            cmd = rustlangpkg.get_package_test_command()
        end
    end

    return cmd
end

return M
