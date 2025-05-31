local Rust = {}
local utils = require("hanger.test_actions.utils")
local term = require("hanger.test_actions.terminal")
local telescope = require("hanger.test_actions.telescope")

--- Checks if the provided mod is a test mod.
--- @param node TSNode test mod node
--- @return boolean result
local function is_test_mod(node)
    local parent = node:parent()
    if not parent then
        return false
    end

    for i=0, parent:child_count()-1 do
        local child = parent:child(i)
        if not child then
            return false
        end

        if child:id() ==  node:id() then
            if i > 0 then
                local prev_child = parent:child(i-1)
                if not prev_child then
                    break
                end

                if prev_child:type() == "attribute_item" then
                    local bufnr = vim.api.nvim_get_current_buf()
                    local start_row, start_col, end_row, end_col = prev_child:range()
                    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
                    local attr_text = string.sub(line, start_col + 1, end_col)
                    return attr_text:match("#%[cfg%s*%(%s*test%s*%)%]") ~= nil
                end
            end
            break
        end
    end

    return false
end

--- Checks if the provided function is a test function.
--- @param node TSNode test function node
--- @return boolean result
local function is_test_func(node)
    local parent = node:parent()
    if not parent then
        return false
    end

    for i=0, parent:child_count()-1 do
        local child = parent:child(i)
        if not child then
            return false
        end

        if child:id() ==  node:id() then
            if i > 0 then
                local prev_child = parent:child(i-1)
                if not prev_child then
                    break
                end

                if prev_child:type() == "attribute_item" then
                    local bufnr = vim.api.nvim_get_current_buf()
                    local start_row, start_col, end_row, end_col = prev_child:range()
                    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
                    local attr_text = string.sub(line, start_col + 1, end_col)
                    return attr_text:match("#%[test%]") ~= nil
                end
            end
            break
        end
    end

    return false
end

--- Checks if the current directory has a mod.rs file.
--- @returns boolean
local function has_mod_rs()
    local directory = vim.fn.expand("%:p:h")
    local mod_rs_path = directory .. "/mod.rs"
    return vim.fn.filereadable(mod_rs_path) == 1
end

local function get_test_mods(test_node)
    local modes = {}

    if test_node then
        -- If the test node is a mod_item, include its name as test_node.
        if test_node:type() == "mod_item" then
            local name_node = test_node:field("name")[1]
            if name_node then
                local mod_name = vim.treesitter.get_node_text(name_node, 0) -- 0 = current buffer
                table.insert(modes, mod_name)
            end
        end

        -- Collect parent mod names within the code.
        ---@type TSNode?
        local current = test_node:parent()
        while current do
            if current:type() == "mod_item" then
                local name_node = current:field("name")[1]
                if name_node then
                    local mod_name = vim.treesitter.get_node_text(name_node, 0) -- 0 = current buffer
                    table.insert(modes, mod_name)
                end
            end
            current = current:parent()
        end
    end


    -- If the current file is a singular mod file, add its name to the modes.
    -- If the current file is not a singular mod file, but is a part of it, add its name as well as
    -- the mod name that it is a part of, to the modes.
    -- For example: /users mod with: /users/mod.rs, /users/test.rs
    -- If the test is in /users/test.rs, add 'users', 'test' to the mod names.
    local filename = vim.fn.expand("%:t:r")
    if filename == "mod" or has_mod_rs() then
        local parent_folder = vim.fn.fnamemodify(vim.fn.expand("%:p:h"), ":t")
        table.insert(modes, filename)
        table.insert(modes, parent_folder)
    else
        table.insert(modes, filename)
    end

    return utils.reverse_table(modes)
end

--- Returns the core package name.
local function get_package()
    local current_dir = vim.fn.expand("%:p:h")

    while current_dir ~= "/" do
        if vim.fn.glob(current_dir .. "/Cargo.toml") ~= "" then
            return vim.fn.fnamemodify(current_dir, ":t")
        end

        current_dir = vim.fn.fnamemodify(current_dir, ":h")
    end

    return nil
end

--- Returns test information at the current cursor location.
--- @return string|nil test test function name
--- @return string[]|nil mods An array of module names from outermost to innermost, or nil if not found.
local function get_test_at_cursor()
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, "rust")
    if not parser then
        vim.notify("hanger: rust parser not found", vim.log.levels.INFO)
        return nil, nil
    end

    -- Get node at cursor
    local tree = parser:parse()[1]
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local node = tree:root():named_descendant_for_range(row, col, row, col)

    -- Get test function node or mod node.
    while node and (node:type() ~= "function_item" and node:type() ~= "mod_item") do
        node = node:parent()
    end
    if not node or (node:type() == "function_item" and not is_test_func(node)) or (node:type() == "mod_item" and not is_test_mod(node)) then
        return nil, nil
    end
    local test_node = node

    local func_name = nil

    if node:type() == "function_item" then
        local name_node = test_node:field("name")[1]
        if not name_node then return nil, nil end
        func_name = vim.treesitter.get_node_text(name_node, buf)
    end

    -- Get mods.
    local mods = get_test_mods(test_node)
    if not mods or #mods == 0 then
        print("Cannot find mod name.")
        return
    end

    return func_name, mods
end

--- Builds a `cargo test` command string based on the test context.
--- @param test_name string|nil Name of the test function. Nil if running the whole package.
--- @param mods string[] An array of module names from outermost to innermost.
--- running the whole package
--- @return string cmd The fully constructed `cargo test` command.
local function build_cmd(test_name, mods)
    local package_name = get_package()
    if not package_name then
        vim.notify("hanger: No Cargo.toml found.", vim.log.levels.INFO)
        return ""
    end

    local test_pattern = ""
    if test_name then
        test_pattern = test_name
    end

    for i = #mods, 1, -1 do
        if test_pattern == "" then
            test_pattern = mods[i]
        else
            test_pattern = string.format("%s::%s", mods[i], test_pattern)
        end
    end

    local cmd = string.format(
        "cargo test --package %s --bin %s -- %s",
        package_name,
        package_name,
        test_pattern
    )

    if test_name then
        cmd = string.format("%s --exact", cmd)
    end

    cmd = string.format("%s --show-output", cmd)

    return cmd
end

function Rust.execute_single(config)
    local test_name, mods = get_test_at_cursor()
    if not mods then
        vim.notify("hanger: cursor not within a test function/mod", vim.log.levels.INFO)
        return
    end

    local cmd = build_cmd(test_name, mods)
    term.execute(cmd, config)
end

function Rust.execute_package(config)
    local mods = get_test_mods(nil)
    local cmd = build_cmd(nil, mods)
    term.execute(cmd, config)
end

return Rust
