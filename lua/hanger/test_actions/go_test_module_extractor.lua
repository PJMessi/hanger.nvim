local Go = {}

function Go.get_package_test_command()
    local current_dir_name = vim.fn.expand("%:p:h")
    -- "make test-single path=" .. dirname
    return "go test " .. current_dir_name .. " -v -p 1 ./... --count=1"
end

function Go.get_single_test_command()
    local test_name, suite_name = Go.get_module_names()
    if not test_name then
        print("no test function name found")
        return
    end

    local test_pattern
    if suite_name then
        test_pattern = string.format("^%s$/%s$", suite_name, test_name)
    else
        test_pattern = string.format("^%s$", test_name)
    end

    local current_dir_name = vim.fn.expand("%:p:h")
    return string.format(
        "go test %s -v -p 1 -run '%s' ./... --count=1",
        current_dir_name,
        test_pattern
    )
end

-- get_module_names returns the name of the test function and the name of the
-- suite that the test belongs to (if any).
function Go.get_module_names()
    -- Get the current line number
    local current_line = vim.fn.line(".")
    local test_name = nil
    local suite_name = nil
    local is_suite_test = false

    -- First find the test function
    for i = current_line, 1, -1 do
        local line = vim.fn.getline(i)

        -- Match standalone test: "func TestXxx("
        local standalone_match = string.match(line, "^%s*func%s+(Test[%w_]+)%s*%(")
        if standalone_match then
            return standalone_match, nil
        end

        -- Match test suite method: "func (suite *testSuite) TestXxx("
        local suite_match = string.match(line, "^%s*func%s*%([%w_*%s]+%)%s+(Test[%w_]+)%s*%(")
        if suite_match then
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

return Go
