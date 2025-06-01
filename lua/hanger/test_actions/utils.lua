local M = {}

--- Returns the relative path for the current buffer from the project root.
function M.get_rel_path()
    -- Get the full path of the current file
    local full_path = vim.fn.expand("%:p")

    -- Get the current working directory
    local cwd = vim.fn.getcwd()

    -- Return the relative path by removing the current working directory part
    return string.sub(full_path, #cwd + 2)
end

--- Returns the starting row number for the given node.
function M.get_node_start_row_num(node)
    local start_row, _, _, _ = node:range()
    return start_row
end

function M.reverse_table(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

--- Prints content of the given node.
function M.print_node_text(node)
  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = node:range()

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  if #lines == 0 then return end

  -- Trim the first and last line to match exact column range
  lines[1] = string.sub(lines[1], start_col + 1)
  lines[#lines] = string.sub(lines[#lines], 1, end_col)

  print(table.concat(lines, "\n"))
end

return M
