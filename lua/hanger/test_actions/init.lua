local M = {}
local rust = require("hanger.test_actions.rust")
local go = require("hanger.test_actions.go")
local term = require("hanger.test_actions.terminal")

M.config = {
    output = "term",       -- options: 'term' / 'zellij'
    floating_pane = false, -- only valid for 'zellij' 'output'
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
end

function M.run_single_test()
    local lang_name = vim.bo.filetype
    if lang_name == "rust" then
        rust.execute_single(M.config)
    elseif lang_name == "go" then
        go.execute_single(M.config)
    end
end

function M.run_tests_in_file()
    local lang_name = vim.bo.filetype
    if lang_name == "rust" then
        rust.execute_package(M.config)
    elseif lang_name == "go" then
        go.execute_package(M.config)
    end
end

function M.rerun_test()
    term.execute_cache(M.config)
end

return M
