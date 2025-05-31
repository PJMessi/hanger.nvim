local Javascript = {}
local utils = require("hanger.test_actions.utils")
local term = require("hanger.test_actions.terminal")
local telescope = require("hanger.test_actions.telescope")

--- Jest pattern matching fails when there is special chars in the pattern. This function escapes such special chars.
--- @param text string
--- @return string
local function escape_pattern(text)
    local result  = text:gsub("([%.%+%-%*%?%^%$%(%)%[%]%{%}%|\\])", "\\%1")
    return result
end

--- Builds a `jest` command string based on the test context.
--- @param rel_path string Relative path of the test file.
--- @param test_name? string test description provided in the describe/test/it function call. 
local function build_cmd(rel_path, test_name)
    if test_name then
        local filtered_test_name = escape_pattern(test_name)
        return string.format("./node_modules/.bin/jest ./%s -t '%s' --runInBand", rel_path, filtered_test_name)
    end

    return string.format("./node_modules/.bin/jest ./%s --runInBand", rel_path)
end

--- Checks if the provided node is 'describe', 'test' or 'it' function call. Example: 
--- describe("some test case", ...)
local function is_test_func_call(node)
    if node:type() ~= "call_expression" then
        return false
    end

    local func_name = node:child(0)
    if not (func_name and func_name:type() == "identifier") then
        return false
    end

    local name_text = vim.treesitter.get_node_text(func_name, 0)
    return name_text == "describe" or name_text == "test" or name_text == "it"
end

--- Recursively extracts the full test name from a nested Jest test node.
--- @param node TSNode Treesitter node representing a test/describe/it call
--- @param test_name? string Accumulated space-separated description (for Jest command)
--- @param display_val? string Accumulated display-formatted description (for UI)
--- @return string|nil test_name for Jest command
--- @return string|nil display_name description for Telescope UI
local function extract_test_name(node, test_name, display_val)
    local arg_node = node:child(1)
    if arg_node and arg_node:type() == "arguments" then
        local str_node = arg_node:child(1) -- Usually the first argument
        if str_node and (str_node:type() == "string" or str_node:type() == "template_string") then
            local describe_text = vim.treesitter.get_node_text(str_node, 0)

            describe_text = string.gsub(describe_text, "'", "")
            describe_text = string.gsub(describe_text, "\"", "")

            if not test_name or test_name == "" then
                test_name = describe_text
            else
                test_name = describe_text .. " " .. test_name
            end

            if not display_val or display_val == "" then
                display_val = describe_text
            else
                display_val = describe_text .. " - " .. display_val
            end
        end
    end

    local parent_node = node:parent()
    while parent_node and is_test_func_call(parent_node) == false do
        parent_node = parent_node:parent()
    end

    if parent_node then
        return extract_test_name(parent_node, test_name, display_val)
    end

    return test_name, display_val
end

local function get_lang(is_typescript)
    if is_typescript then
        return "typescript"
    end

    return "javascript"
end

function Javascript.execute_single(config, is_typescript)
    -- Get buffer and parser
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, get_lang(is_typescript))
    if not parser then return nil, nil end

    -- Get node at cursor
    local tree = parser:parse()[1]
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local node = tree:root():named_descendant_for_range(row, col, row, col)

    -- Find containing describe function call
    while node and is_test_func_call(node) == false do
        node = node:parent()
    end
    if not node then return nil, nil end

    local test_description = extract_test_name(node)
    local rel_path = utils.get_rel_path()
    local cmd = build_cmd(rel_path, test_description)
    term.execute(cmd, config)
end

function Javascript.execute_package(config)
    local rel_path = utils.get_rel_path()
    local cmd = build_cmd(rel_path)
    term.execute(cmd, config)
end

-- Returns 'describe' or 'test' or 'it'.
local function extract_test_type(node, query, root, buf)
    local test_type
    for id2, node2 in query:iter_captures(root, buf) do
        if query.captures[id2] == "func_name" and node2 == node:field("function")[1] then
            test_type = vim.treesitter.get_node_text(node2, buf)
            break
        end
    end

    return test_type
end

function Javascript.show_runnables(config, is_typescript)
    local lang = get_lang(is_typescript)

    -- Get buffer and parser
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, lang)
    if not parser then return {} end

    -- Get the root node
    local root = parser:parse()[1]:root()

    -- Query for all function and method declarations
    local query_str = [[
      (call_expression
        function: (identifier) @func_name
        (#match? @func_name "^(describe|test|it)$")) @test_call
    ]]


    local query = vim.treesitter.query.parse(lang, query_str)

    local cmds = {}
    local rel_path = utils.get_rel_path()

    for id, node, metadata in query:iter_captures(root, buf) do
        local capture_name = query.captures[id]
        if capture_name == "test_call" then
            local start_row = utils.get_node_start_row_num(node)
            local test_description, display_value = extract_test_name(node)
            local cmd = build_cmd(rel_path, test_description)
            local test_type = extract_test_type(node, query, root, buf)

            table.insert(cmds, {
                value=cmd,
                display_name=display_value,
                test_row_num = start_row,
                filename = vim.api.nvim_buf_get_name(buf),
                test_type = test_type
            })
        end
    end

    config.show_previewer = true
    config.show_test_type = true
    telescope.show_popups(cmds, config)
end

return Javascript
