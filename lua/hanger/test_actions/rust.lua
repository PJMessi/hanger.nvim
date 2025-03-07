local Rust = {}
local utils = require("hanger.test_actions.utils")
local term = require("hanger.test_actions.terminal")
local telescope = require("hanger.test_actions.telescope")

local function build_cmd(runnable)
    -- Build test command from runnable.
    local cmd = "cargo"

    -- Setup cargo arguments.
    for _, val in ipairs(runnable.args.cargoArgs) do
        cmd = cmd .. " " .. val
    end

    -- Setup rust arguments.
    if #runnable.args.executableArgs > 0 then
        cmd = cmd .. " --"
        for _, val in ipairs(runnable.args.executableArgs) do
            cmd = cmd .. " " .. val
        end
    end

    return cmd
end

local function validate_runnables_result(err, result)
    if err then
        vim.notify("rust-analyzer error while determining runnables", vim.log.levels.ERROR)
        return false
    end

    if #result == 0 then
        vim.notify("rust-analyzer returned empty runnables" .. err.message, vim.log.levels.ERROR)
        return false
    end

    return true
end

function Rust.execute_single(config)
    -- Extract test func name to
    local test_func_name = utils.get_outer_function_name()
    if test_func_name == nil then
        vim.notify("could not extract test function name", vim.log.levels.WARN)
        return
    end

    -- Request rust-analyzer for runnables.
    local params = vim.lsp.util.make_position_params()
    vim.lsp.buf_request(0, "experimental/runnables", params, function(err, result, _, _)
        if validate_runnables_result(err, result) == false then
            return
        end

        -- Select the runnable that includes the test function name.
        for _, runnable in ipairs(result) do
            if string.find(runnable.label, test_func_name) then
                -- Build command from runnable.
                local cmd = build_cmd(runnable)

                vim.notify(cmd, vim.log.levels.INFO)

                -- Run the command in a terminal.
                term.execute(cmd, config)
            end
        end
    end)
end

function Rust.execute_package(config)
    -- Request rust-analyzer for runnables.
    local params = vim.lsp.util.make_position_params()
    vim.lsp.buf_request(0, "experimental/runnables", params, function(err, result, _, _)
        if validate_runnables_result(err, result) == false then
            return
        end

        -- Select the runnable that includes the test function name.
        for _, runnable in ipairs(result) do
            if utils.starts_with(runnable.label, "test-mod") then
                -- Build command from runnable.
                local cmd = build_cmd(runnable)

                vim.notify(cmd, vim.log.levels.INFO)

                -- Run the command in a terminal.
                term.execute(cmd, config)
            end
        end
    end)
end

function Rust.show_runnables(config)
    -- Request rust-analyzer for runnables.
    local params = vim.lsp.util.make_position_params()
    vim.lsp.buf_request(0, "experimental/runnables", params, function(err, result, _, _)
        if validate_runnables_result(err, result) == false then
            return
        end

        -- Select the runnable that includes the test function name.
        local cmds = {}
        for _, runnable in ipairs(result) do
            -- Build command from runnable.
            local cmd = build_cmd(runnable)
            table.insert(cmds, cmd)
        end

        -- Display as popup.
        telescope.show_popups(cmds, config)
    end)
end

return Rust
