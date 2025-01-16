local M = {}

local cmd_cache = ""
local use_zellij = true

local function open_terminal(cmd)
    local starting_win = vim.api.nvim_get_current_win()

    if use_zellij then
        -- Execute the Zellij command
        local zellij_cmd = "zellij action new-pane -f -- " .. cmd
        vim.fn.system(zellij_cmd)

        -- -- Return to the original window after execution
        -- if vim.api.nvim_win_is_valid(starting_win) then
        --     vim.api.nvim_set_current_win(starting_win)
        -- end
        return
    end

    vim.cmd("split")
    -- vim.cmd("term " .. cmd)
    vim.cmd("term echo '" .. cmd .. "\\n' && " .. cmd)
    vim.cmd("resize | wincmd J")

    -- Get the terminal window and buffer
    local term_win = vim.api.nvim_get_current_win()

    vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(term_win),
        callback = function()
            -- Check if our original window still exists
            if vim.api.nvim_win_is_valid(starting_win) then
                vim.api.nvim_set_current_win(starting_win)
            end
        end,
        once = true
    })
end

function M.run_single_test()
    local file_ext = vim.fn.expand("%:e")
    if file_ext ~= "go" then
        print("test not configured for '." .. file_ext .. "' extension")
        return
    end

    -- Get test pattern using the helper function
    local test_name, suite_name = GetGoTestFuncName()
    if not test_name then
        print("no test function name found")
        return -- Exit if no test function is found
    end

    -- Build the test pattern
    local test_pattern
    if suite_name then
        -- Suite test
        test_pattern = string.format("^%s$/%s$", suite_name, test_name)
    else
        -- Regular test
        test_pattern = string.format("^%s$", test_name)
    end

    -- Get the current file directory name
    local dirname = vim.fn.expand("%:p:h")

    -- Build the command
    local cmd = string.format(
        "go test %s -v -p 1 -run '%s' ./... --count=1",
        dirname,
        test_pattern
    )

    -- Cache the command
    cmd_cache = cmd

    open_terminal(cmd)
end

function GetGoTestFuncName()
    local current_line = vim.fn.line(".") -- Get the current line number
    local test_name = nil
    local suite_name = nil
    local is_suite_test = false

    -- First find the test function
    for i = current_line, 1, -1 do
        local line = vim.fn.getline(i)
        -- Match standalone test: "func TestXxx("
        local standalone_match = string.match(line, "^%s*func%s+(Test[%w_]+)%s*%(")
        -- Match test suite method: "func (suite *testSuite) TestXxx("
        local suite_match = string.match(line, "^%s*func%s*%([%w_*%s]+%)%s+(Test[%w_]+)%s*%(")

        if standalone_match then
            return standalone_match, nil -- Return immediately for standalone test
        elseif suite_match then
            test_name = suite_match
            is_suite_test = true
            break
        end
    end

    -- Only continue searching for suite name if we found a suite test
    if is_suite_test then
        -- Look through the whole file for the suite runner
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for i, line in ipairs(lines) do
            -- First look for potential suite runner functions
            local runner_match = string.match(line, "^%s*func%s+(Test[%w_]+)%s*%(t%s*%*?testing%.T%)%s*{?%s*$")
            if runner_match then
                -- Look ahead a few lines for suite.Run call
                for j = i, math.min(i + 5, #lines) do -- Check next 5 lines
                    if string.match(lines[j], "suite%.Run") then
                        suite_name = runner_match
                        goto found_suite
                    end
                end
            end
        end

        ::found_suite::
        if test_name and suite_name then
            return test_name, suite_name
        end
    end

    return nil, nil
end

function M.rerun_test()
    if cmd_cache == "" then
        print("you have not ran any tests this session to rerun")
        return
    end

    -- Open a new split terminal and run the command
    open_terminal(cmd_cache)
end

function M.run_tests_in_file()
    local file_ext = vim.fn.expand("%:e")

    if file_ext == "go" then
        -- Get the current file directory name
        local dirname = vim.fn.expand("%:p:h")

        -- Build the command to run the specific test function
        -- local cmd = "make test-single path=" .. dirname
        local cmd = "go test " .. dirname .. " -v -p 1 ./... --count=1"

        -- Cache the command
        cmd_cache = cmd

        -- Open a new split terminal and run the command
        open_terminal(cmd)
    else
        print("test not configured for '." .. file_ext .. "' extension")
        return
    end
end

return M
