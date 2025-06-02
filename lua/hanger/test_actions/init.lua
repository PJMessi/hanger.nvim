local M = {}
local rust = require("hanger.test_actions.rust")
local go = require("hanger.test_actions.go")
local javascript = require("hanger.test_actions.javascript")
local typescript = require("hanger.test_actions.typescript")
local term = require("hanger.test_actions.terminal")

M.config = {
    output = "term",       -- options: 'term' / 'zellij'
    floating_pane = false, -- only valid for 'zellij' 'output'
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
end

function M.run_test()
    local lang_name = vim.bo.filetype
    if lang_name == "rust" then
        rust.execute_single(M.config)
    elseif lang_name == "go" then
        go.execute_single(M.config)
    elseif lang_name == "javascript" then
        javascript.execute_single(M.config)
    elseif lang_name == "typescript" then
        typescript.execute_single(M.config)
    else
        -- vim.notify("language not supported", vim.log.levels.ERROR)
    end
end

function M.run_all_tests()
    local lang_name = vim.bo.filetype
    if lang_name == "rust" then
        rust.execute_package(M.config)
    elseif lang_name == "go" then
        go.execute_package(M.config)
    elseif lang_name == "javascript" then
        javascript.execute_package(M.config)
    elseif lang_name == "typescript" then
        typescript.execute_package(M.config)
    else
        vim.notify("language not supported", vim.log.levels.ERROR)
    end
end

function M.rerun_test()
    term.execute_cache(M.config)
end

function M.show_tests()
    local lang_name = vim.bo.filetype
    if lang_name == "rust" then
        rust.show_tests(M.config)
    elseif lang_name == "go" then
        go.show_tests(M.config)
    elseif lang_name == "javascript" then
        javascript.show_tests(M.config)
    elseif lang_name == "typescript" then
        typescript.show_tests(M.config)
    else
        vim.notify("language not supported", vim.log.levels.ERROR)
    end
end

return M
