local Go = {}
local term = require("hanger.test_actions.terminal")
local telescope = require("hanger.test_actions.telescope")

local function find_suite_name(buf, node)
    -- Get receiver type
    local receiver = node:field("receiver")[1]
    if not receiver then return nil end

    local receiver_text = vim.treesitter.get_node_text(receiver, buf)
    local suite_type = receiver_text:match("*([%w_]+)")

    if not suite_type or not suite_type:match("Suite$") then return nil end

    -- Get the root node and parse all function declarations
    local root = vim.treesitter.get_parser(buf):parse()[1]:root()

    -- Query for all function declarations in the file
    local query_str = [[
      (function_declaration) @func_decl
    ]]

    local query = vim.treesitter.query.parse("go", query_str)

    for _, func_node in query:iter_captures(root, buf) do
        -- Look for a function that includes suite.Run with our suite type
        local func_text = vim.treesitter.get_node_text(func_node, buf)

        -- Check for suite runner/wrapper func name.
        -- The func could have 'suite.Run(t, new(SuiteName))' or 'suite.Run(t, &SuiteName{})', or
        -- a func call to get SuiteName, or many other ways to get SuiteName struct ptr. So it is
        -- not really feasible to check for every way. So limit the check to have suite.Run with the
        -- suite name only.
        if func_text:match("suite%.Run") and func_text:match(suite_type) then
            -- Extract the function name
            local name_node = func_node:field("name")[1]
            if name_node then
                return vim.treesitter.get_node_text(name_node, buf)
            end
        end
    end

    return nil
end

local function is_test_func(func_name)
    return func_name:match("^Test")
end

local function get_test_func_name()
    -- Get buffer and parser
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, "go")
    if not parser then return nil, nil end

    -- Get node at cursor
    local tree = parser:parse()[1]
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local node = tree:root():named_descendant_for_range(row, col, row, col)

    -- Find containing function or method
    while node and node:type() ~= "function_declaration" and node:type() ~= "method_declaration" do
        node = node:parent()
    end
    if not node then return nil, nil end

    -- Get function name
    local name_node = node:field("name")[1]
    if not name_node then return nil, nil end
    local func_name = vim.treesitter.get_node_text(name_node, buf)

    -- Check if it's a test function
    if not is_test_func(func_name) then return nil, nil end

    -- If it's a method, find the suite runner
    if node:type() == "method_declaration" then
        local suite_wrapper = find_suite_name(buf, node)
        return true, func_name, suite_wrapper
    end

    -- Regular test or suite runner
    return false, func_name, nil
end

local function get_package_rel_path()
    local file_path = vim.fn.expand("%")
    return vim.fn.fnamemodify(file_path, ":h")
end

local function build_cmd(rel_path, test_func_name, is_suite_test, suite_name)
    -- It is nil for package test commands.
    if test_func_name == nil then
        return string.format("go test ./%s -count=1 -v", rel_path)
    end

    -- It is nil for default/normal test cases.
    if is_suite_test == nil or is_suite_test == false then
        return string.format("go test ./%s -run ^%s$ -count=1 -v", rel_path, test_func_name)
    end

    -- It is nil if we were unable to find out the suite wrapper name. Use testify.m flag to execute
    -- it uniquely.
    if suite_name == nil then
        return string.format("go test ./%s -testify.m ^%s$ -count=1 -v", rel_path, test_func_name)
    end

    return string.format("go test ./%s -run ^%s$/%s$ -count=1 -v", rel_path, suite_name, test_func_name)
end

function Go.execute_single(config)
    local is_suite_test, test_func_name, suite_name = get_test_func_name()
    if test_func_name == nil then
        vim.notify("could not extract test function name", vim.log.levels.WARN)
        return
    end

    local rel_path = get_package_rel_path()
    local cmd = build_cmd(rel_path, test_func_name, is_suite_test, suite_name)
    term.execute(cmd, config)
end

function Go.execute_package(config)
    local rel_path = get_package_rel_path()
    local cmd = build_cmd(rel_path)
    term.execute(cmd, config)
end

function Go.show_runnables(config)
    -- Get buffer and parser
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, "go")
    if not parser then return {} end

    -- Get the root node
    local root = parser:parse()[1]:root()

    -- Query for all function and method declarations
    local query_str = [[
      (function_declaration) @func
      (method_declaration) @method
    ]]

    local query = vim.treesitter.query.parse("go", query_str)

    local cmds = {}
    local rel_path = get_package_rel_path()

    for id, node in query:iter_captures(root, buf) do
        local capture_name = query.captures[id]
        local name_node = node:field("name")[1]

        if name_node then
            local func_name = vim.treesitter.get_node_text(name_node, buf)

            -- Check if it's a test function (starts with Test)
            if is_test_func(func_name) then
                if capture_name == "func" then
                    table.insert(cmds, build_cmd(rel_path, func_name, false))
                elseif capture_name == "method" then
                    -- Method on a suite
                    local suite_wrapper = find_suite_name(buf, node)
                    table.insert(cmds, build_cmd(rel_path, func_name, true, suite_wrapper))
                end
            end
        end
    end

    telescope.show_popups(cmds, config)
end

return Go
