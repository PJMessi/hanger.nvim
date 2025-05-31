local Go = {}
local term = require("hanger.test_actions.terminal")
local telescope = require("hanger.test_actions.telescope")
local utils = require("hanger.test_actions.utils")

--- Checks if the provided function is a test function.
--- @param func_name string
--- @return boolean result
local function is_test_func(func_name)
    return func_name:match("^Test")
end

--- Recursively checks the suite runner name for the given suite name.
--- @param suite_name string The suite name, whose runner func is to be determined.
--- @param func_node TSNode The Tree-sitter node representing a function declaration.
--- @param buf integer The buffer number the node belongs to.
--- @param func_text? string (Optional) Precomputed function text; if not provided, it will be extracted.
--- @return string|nil The test function name that matches the suite, or nil if none is found.
local function check_node_for_suite_runner(suite_name, func_node, buf, func_text)
    if not func_text then
        func_text = vim.treesitter.get_node_text(func_node, buf)
    end

    if func_text:match(suite_name) then
        local func_name_node = func_node:field("name")[1]

        if func_name_node then
            func_text = vim.treesitter.get_node_text(func_name_node, buf)

            if (is_test_func(func_text)) then
                return func_text
            end

            return check_node_for_suite_runner(suite_name, func_node, buf, func_text)
        end

        return nil
    end
end

--- Returns the test suite info for the given test node in the current buffer.
--- @param buf integer current buffer
--- @param node TSNode test node
--- @return string|nil suite suite name
--- @return string|nil suite_runner name of the functin that runs the suite
local function get_suite_info(buf, node)
    -- Get receiver type
    local receiver = node:field("receiver")[1]
    if not receiver then return nil end

    local receiver_text = vim.treesitter.get_node_text(receiver, buf)
    local suite = receiver_text:match("*([%w_]+)")

    if not suite then
        return nil, nil
    end

    -- Get the root node and parse all function declarations
    local root = vim.treesitter.get_parser(buf):parse()[1]:root()

    -- Query for all function declarations in the file
    local func_query = vim.treesitter.query.parse("go", [[
      (function_declaration) @func_decl
    ]])

    for _, func_node in func_query:iter_captures(root, buf) do
        -- Look for a function that includes suite.Run with our suite type
        local suite_runner = check_node_for_suite_runner(suite, func_node, buf)
        if suite_runner then
            return suite, suite_runner
        end
    end

    return nil, nil
end

--- Returns test information at the current cursor location.
--- @return string|nil test test function name
--- @return string|nil suite name of the suite the test belongs to. Nil if not a suite.
--- @return string|nil suite_runner name of the func that runs the suite. Nil if not a suite.
local function get_test_at_cursor()
    -- Get buffer and parser
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, "go")
    if not parser then
        vim.notify("hanger: golang parser not found", vim.log.levels.INFO)
        return nil, nil, nil
    end

    -- Get node at cursor
    local tree = parser:parse()[1]
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local node = tree:root():named_descendant_for_range(row, col, row, col)

    -- Find containing function or method
    while node and node:type() ~= "function_declaration" and node:type() ~= "method_declaration" do
        node = node:parent()
    end
    if not node then return nil, nil, nil end

    -- Get function name
    local name_node = node:field("name")[1]
    if not name_node then return nil, nil, nil end
    local func_name = vim.treesitter.get_node_text(name_node, buf)

    if not is_test_func(func_name) then
        return nil, nil, nil
    end
    local test_name = func_name

    -- If it's a method, find the suite runner
    if node:type() == "method_declaration" then
        local suite, suite_runner = get_suite_info(buf, node)
        return test_name, suite, suite_runner
    end

    return test_name, nil, nil
end

--- Returns the relative path for the current package.
local function get_package_rel_path()
    local file_dir = vim.fn.expand("%:p:h")
    local cwd = vim.fn.getcwd()
    return vim.fn.fnamemodify(file_dir, ":s?" .. cwd .. "/??")
end

--- Builds a `go test` command string based on the test context.
--- @param test_name string|nil Name of the test function. Nil if running the whole package.
--- @param is_suite boolean|nil true if the test belongs to a suite.
--- @param suite_runner string|nil The name of the func that runs the suite. Nil if unknown.
--- @return string cmd The fully constructed `go test` command.
local function build_cmd(test_name, is_suite, suite_runner)
    local rel_path = get_package_rel_path()

    -- It is nil for package test commands.
    if test_name == nil then
        return string.format("go test ./%s -count=1 -v", rel_path)
    end

    -- It is nil for default/normal test cases.
    if is_suite == nil or is_suite == false then
        return string.format("go test ./%s -run ^%s$ -count=1 -v", rel_path, test_name)
    end

    -- It is nil if we were unable to find out the suite wrapper name. Use testify.m flag to execute
    -- it uniquely.
    -- NOTE: If there are 1+ exactly same test method names, but belongs to 2 different test suites,
    -- testify would not be able to separate the suites. So, no matter which test the cursor is on,
    -- it will always execute the last one.
    if suite_runner == nil then
        return string.format("go test ./%s -testify.m ^%s$ -count=1 -v", rel_path, test_name)
    end

    return string.format("go test ./%s -run ^%s$/%s$ -count=1 -v", rel_path, suite_runner, test_name)
end

function Go.execute_single(config)
    local test_name, suite, suite_runner = get_test_at_cursor()

    if test_name == nil then
        vim.notify("hanger: cursor not within a test function", vim.log.levels.INFO)
        return
    end

    local is_suite = suite ~= nil
    local cmd = build_cmd(test_name, is_suite, suite_runner)
    term.execute(cmd, config)
end

function Go.execute_package(config)
    local cmd = build_cmd()
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
    local filename = vim.api.nvim_buf_get_name(buf)
    for id, node in query:iter_captures(root, buf) do
        local capture_name = query.captures[id]
        local name_node = node:field("name")[1]

        if name_node then
            local func_name = vim.treesitter.get_node_text(name_node, buf)

            if is_test_func(func_name) then
                local start_row = utils.get_node_start_row_num(node)

                if capture_name == "func" then
                    local cmd = build_cmd(func_name, false)
                    table.insert(cmds, {
                        value=cmd,
                        display_name=func_name,
                        test_row_num = start_row,
                        filename = filename,
                        test_type = "default"
                    })

                elseif capture_name == "method" then
                    local suite_name, suite_runner_name = get_suite_info(buf, node)
                    local cmd = build_cmd(func_name, true, suite_runner_name)
                    table.insert(cmds, {
                        value=cmd,
                        display_name=func_name,
                        test_row_num = start_row,
                        filename = filename,
                        test_type = suite_name
                    })
                end
            end
        end
    end

    config.show_test_type = true
    config.show_previewer = true
    telescope.show_popups(cmds, config)
end

return Go
