local M = {}

local cmd_cache = ""

function M.run_single_test()
    local file_ext = vim.fn.expand("%:e")

    local func_name
    if file_ext == "go" then
        func_name = GetGoTestFuncName()
        if not func_name then return end -- Exit if no test function is found
    else
        print("test not configured for '." .. file_ext .. "' extension")
        return
    end

    -- Get the current file directory name
    local dirname = vim.fn.expand("%:p:h")
    local cmd = "make test-single name=" .. func_name .. " path=" .. dirname

    -- cache the cmd
    cmd_cache = cmd

    print(cmd)
    -- Open a new split terminal and run the command
    vim.cmd("split")
    vim.cmd("term " .. cmd)
end

function GetGoTestFuncName()
    local current_line = vim.fn.line(".") -- Get the current line number
    local func_name = nil

    -- Search backwards for a line that starts with 'func Test' and matches Go test naming conventions
    for i = current_line, 1, -1 do
        local line = vim.fn.getline(i)
        local match = string.match(line, "^%s*func%s+(Test[%w_]+)%s*%(")
        if match then
            func_name = match
            break
        end
    end

    if func_name then
        return func_name
    else
        print("no test function found")
        return nil
    end
end

function M.rerun_single_test()
    if cmd_cache == "" then
        print("no tests to rerun")
        return
    end

    -- Open a new split terminal and run the command
    vim.cmd("split")
    vim.cmd("term " .. cmd_cache)
end

function M.run_tests_in_file()
    local file_ext = vim.fn.expand("%:e")

    if file_ext == "go" then
        -- Get the current file directory name
        local dirname = vim.fn.expand("%:p:h")

        -- Build the command to run the specific test function
        local cmd = "make test-single path=" .. dirname

        print(cmd)

        -- Open a new split terminal and run the command
        vim.cmd("split")
        vim.cmd("term " .. cmd)
    else
        print("Test not configured")
        return
    end
end

return M
