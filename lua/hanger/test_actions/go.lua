local Go = {}
local term = require("hanger.test_actions.terminal")

local function find_suite_name(buf, node)
    -- Get the code as text for simpler searching
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local code = table.concat(lines, "\n")

    -- Get receiver type
    local receiver = node:field("receiver")[1]
    if receiver then
        local receiver_text = vim.treesitter.get_node_text(receiver, buf)
        local suite_type = receiver_text:match("*([%w_]+)")

        if suite_type and suite_type:match("Suite$") then
            -- Find the suite runner using simple pattern matching
            local suite_runner_pattern = "func%s+([Test][%w_]+)%s*%(.*%)[^{]*{[^}]*suite%.Run%s*%([^,]+,%s*new%s*%(" ..
                suite_type .. "%s*%)%)"
            local suite_runner = code:match(suite_runner_pattern)

            if suite_runner then
                return suite_runner
            end
        end
    end

    return nil
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
    if not func_name:match("^Test") then return nil, nil end

    -- If it's a method, find the suite runner
    if node:type() == "method_declaration" then
        local suite_wrapper = find_suite_name(buf, node)
        return func_name, suite_wrapper
    end

    -- Regular test or suite runner
    return func_name, nil
end

local function get_package_rel_path()
    local file_path = vim.fn.expand("%")
    return vim.fn.fnamemodify(file_path, ":h")
end

local function build_cmd(rel_path, test_func_name, suite_name)
    if test_func_name == nil then
        return string.format("go test ./%s -count=1 -v", rel_path)
    end

    if suite_name == nil then
        return string.format("go test ./%s -run ^%s$ -count=1 -v", rel_path, test_func_name)
    end

    return string.format("go test ./%s -run ^%s$/%s$ -count=1 -v", rel_path, suite_name, test_func_name)
end

function Go.execute_single(config)
    local test_func_name, suite_name = get_test_func_name()
    if test_func_name == nil then
        vim.notify("could not extract test function name", vim.log.levels.WARN)
        return
    end

    local rel_path = get_package_rel_path()
    local cmd = build_cmd(rel_path, test_func_name, suite_name)
    term.execute(cmd, config)
end

function Go.execute_package(config)
    local rel_path = get_package_rel_path()
    local cmd = build_cmd(rel_path, nil)
    term.execute(cmd, config)
end

function Go.show_runnables(config)
end

return Go
