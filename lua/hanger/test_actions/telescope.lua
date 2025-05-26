local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local term = require("hanger.test_actions.terminal")

local Telescope = {}

function Telescope.show_popups(cmds, config)
    pickers.new({
        layout_config = {
            width = 0.6,  -- 60% of screen width
            height = 0.4, -- 40% of screen height
            -- Optional: control preview window size
            preview_width = 0.5 -- 50% of picker width
        },
    }, {
        prompt_title = "Select runnable",
        finder = finders.new_table({
            results = cmds,
            entry_maker = function(entry)
                return {
                  value = entry.value,
                  display = entry.display,
                  ordinal = entry.display,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
            -- This function is called when an item is selected
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if selection then
                    -- print(vim.inspect(selection))
                    term.execute(selection.value, config)
                end
            end)
            return true
        end,
    }):find()
end

return Telescope
