local M = {}

local function_nodes = {
    rust = "function_item",
    lua = "function_definition",
    python = "function_definition",
    javascript = "function_declaration",
    typescript = "function_declaration",
    go = "function_declaration",
    c = "function_definition",
    cpp = "function_definition",
    java = "method_declaration",
}

-- Returns the function name within which the cursor lies currently.
function M.get_outer_function_name()
    local ts_utils = require("nvim-treesitter.ts_utils")

    local node = ts_utils.get_node_at_cursor()
    if not node then
        vim.notify("no nodes found at the cursor", vim.log.levels.WARN)
        return nil
    end

    local lang_name = vim.bo.filetype
    local func_type = function_nodes[lang_name]
    if not func_type then
        vim.notify("unsupported programming language", vim.log.levels.WARN)
        return nil
    end

    -- Traverse up the AST to find the nearest function node
    while node do
        if node:type() == func_type then
            local name_node = node:field("name")[1]
            if name_node then
                return vim.treesitter.get_node_text(name_node, 0)
            end
        end
        node = node:parent()
    end

    return nil
end

-- Checks if the string has prefix.
function M.starts_with(str, prefix)
    -- Handle nil inputs
    if str == nil or prefix == nil then
        return false
    end

    -- Handle empty prefix (everything starts with an empty string)
    if prefix == "" then
        return true
    end

    -- Make sure str is at least as long as prefix
    if #str < #prefix then
        return false
    end

    -- Check if the beginning of str matches prefix
    return string.sub(str, 1, #prefix) == prefix
end

return M
