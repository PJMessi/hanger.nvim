local M = {}

M.dispay_make_commands = function()
    print("we are hereeee")
    -- Use telescope UI for harpoon
    local conf = require("telescope.config").values

    local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
            table.insert(file_paths, item.value)
        end

        require("telescope.pickers").new({}, {
            prompt_title = "Make Commands",
            finder = require("telescope.finders").new_table({
                results = file_paths,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = entry,
                        ordinal = entry
                    }
                end
            }),
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                local actions = require "telescope.actions"
                local action_state = require "telescope.actions.state"
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry().path
                    print(selection)
                    -- local selection = action_state.get_selected_entry()
                    -- -- print(vim.inspect(selection))
                    -- vim.api.nvim_put({ selection[1] }, "", false, true)
                end)
                return true
            end
        }):find()
    end

    vim.keymap.set("n", "<leader>m",
        function()
            local custom_list = {
                items = {
                    { value = "dummy1", command = "echo 'Running dummy1 command'" },
                    { value = "dummy2", command = "echo 'Running dummy2 command'" },
                    { value = "dummy3", command = "echo 'Running dummy3 command'" }
                }
            }

            toggle_telescope(custom_list)
        end,
        { desc = "Open harpoon window" })
end

return M
