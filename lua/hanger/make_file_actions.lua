local M = {}

local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local previewers = require('telescope.previewers')

local function execute_cmd_in_terminal(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    if selection then
        local command = "make " .. selection.value .. "\n"

        -- Open terminal and execute command.
        vim.cmd("split")
        vim.cmd("term " .. command)
        vim.cmd("startinsert")

        -- Open terminal, send command to terminal and execute it. Give terminal
        -- control to the user.
        -- vim.cmd('botright new | terminal')
        -- local term_bufnr = vim.api.nvim_get_current_buf()
        -- vim.cmd('startinsert')
        -- vim.api.nvim_chan_send(vim.b[term_bufnr].terminal_job_id, command)
    end
end

local function create_previewer(make_file_path)
    return previewers.new_buffer_previewer {
        title = "Makefile",
        define_preview = function(self, entry, _)
            conf.buffer_previewer_maker(make_file_path, self.state.bufnr, {
                bufname = self.state.bufname,
                callback = function()
                    -- Extract command and escape special chars.
                    local cmd_name = vim.fn.escape(entry.value, "^$.*+?()[]{}\\|-_:")

                    local bufnr = self.state.bufnr

                    -- Clear existing highlights, if any
                    vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)

                    -- Find the line that matches the selected command
                    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                    for i, line in ipairs(lines) do
                        -- Match exactly at the start of the line that is followed by ':'
                        if vim.fn.match(line, "^" .. cmd_name) ~= -1 then
                            -- Highlight the matching line
                            vim.api.nvim_buf_add_highlight(bufnr, -1, "Search", i - 1, 0, -1)
                            break
                        end
                    end
                end
            })
        end
    }
end

local function toggle_telescope(cmd_names, makefile_path)
    require("telescope.pickers").new({}, {
        prompt_title = "Make Commands",
        finder = require("telescope.finders").new_table({
            results = cmd_names,
            entry_maker = function(entry)
                return {
                    -- It's best practice to have a value reference to the original entry, that way we will always have access to the complete table in our action.
                    value = entry,
                    display = entry,
                    -- The ordinal is also required, which is used for sorting. As already mentioned this allows us to have different display and sorting values. This allows display to be more complex with icons and special indicators but ordinal could be a simpler sorting key
                    ordinal = entry
                }
            end
        }),
        previewer = create_previewer(makefile_path),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
            map('i', '<CR>', execute_cmd_in_terminal)
            map('n', '<CR>', execute_cmd_in_terminal)
            return true
        end
    }):find()
end

local function extract_makecmds(makefile_path)
    local makecmd_regex = "^([^%s%.#][^:]+):"
    local make_cmds = {}
    local file = io.open(makefile_path, "r")
    if file then
        for line in file:lines() do
            local makecmd = line:match(makecmd_regex)
            if makecmd then
                table.insert(make_cmds, makecmd)
            end
        end
    else
        print("Makefile not found")
        return make_cmds
    end

    return make_cmds
end

M.dispay_make_commands = function()
    local makefile_path = "./Makefile"
    local make_cmds = extract_makecmds(makefile_path)
    toggle_telescope(make_cmds, makefile_path)
end

return M
