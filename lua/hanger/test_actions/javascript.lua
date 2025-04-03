local Javascript = {}
local utils = require("hanger.test_actions.utils")
local term = require("hanger.test_actions.terminal")
local telescope = require("hanger.test_actions.telescope")

local function build_cmd(rel_path, test_description_message)
    if test_description_message then
        return string.format("./node_modules/.bin/jest ./%s -t '%s'", rel_path, test_description_message)
    end

    return string.format("./node_modules/.bin/jest ./%s", rel_path)
end

-- Checks if the provided node is 'describe', 'test' or 'it' function call. Example: describe("some test case", ...)
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

-- Extracts the test description message.
local function extract_description(node, description)
    local arg_node = node:child(1)
    if arg_node and arg_node:type() == "arguments" then
        local str_node = arg_node:child(1) -- Usually the first argument
        if str_node and (str_node:type() == "string" or str_node:type() == "template_string") then
            local describe_text = vim.treesitter.get_node_text(str_node, 0)
            describe_text = string.gsub(describe_text, "'", "")
            describe_text = string.gsub(describe_text, "\"", "")
            if not description or description == "" then
                description = describe_text
            else
                description = describe_text .. " " .. description
            end

            print(description)
        end
    end

    node = node:parent()
    while node and is_test_func_call(node) == false do
        node = node:parent()
    end

    if node then
        description = extract_description(node, description)
    end

    return description
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

    local test_description = extract_description(node, "")
    local rel_path = utils.get_rel_path()
    local cmd = build_cmd(rel_path, test_description)
    term.execute(cmd, config)
end

function Javascript.execute_package(config)
    local rel_path = utils.get_rel_path()
    local cmd = build_cmd(rel_path)
    term.execute(cmd, config)
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
            -- For full function call nodes
            local test_description = extract_description(node, "")
            local cmd = build_cmd(rel_path, test_description)
            table.insert(cmds, cmd)
        end
    end

    telescope.show_popups(cmds, config)
end

return Javascript
