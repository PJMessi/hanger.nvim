local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local term = require("hanger.test_actions.terminal")
local previewers = require("telescope.previewers")
local Telescope = {}

function Telescope.show_popups(cmds, config)
    local has_row = false
    for _, entry in ipairs(cmds) do
      if entry.row then
        has_row = true
        break
      end
    end

    pickers.new({
        layout_config = {
            width = 0.6,  -- 60% of screen width
            height = 0.8, -- 40% of screen height
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
                  filename = entry.filename,
                  row = entry.row,
                }
            end,
        }),
        previewer = has_row and previewers.new_buffer_previewer({
            title = "Preview",
            define_preview = function(self, entry, status)
              local filepath = entry.filename or vim.api.nvim_buf_get_name(0)
              local bufnr = self.state.bufnr
              local win = status.preview_win

              -- Use telescope's built-in file reading with highlighting
              conf.buffer_previewer_maker(filepath, bufnr, {
                winid = win,
                bufname = self.state.bufname,
                callback = function(bufnr2)
                  -- Set cursor position and highlight row after file is loaded and highlighted
                  local row = entry.row
                  if row then
                    vim.schedule(function()
                      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(bufnr2) then
                        local total_lines = vim.api.nvim_buf_line_count(bufnr2)
                        local target_row = row + 1
                        print("moving cursor to row:", target_row, "of", total_lines)

                        if target_row >= 1 and target_row <= total_lines then
                          -- Set cursor position
                          vim.api.nvim_win_set_cursor(win, { target_row, 0 })

                          -- Set window view to show target row at the top
                          vim.api.nvim_win_call(win, function()
                            vim.fn.winrestview({
                              topline = target_row,
                              lnum = target_row,
                              col = 0,
                              curswant = 0
                            })
                          end)

                          -- Create highlight group for the target row if it doesn't exist
                          vim.api.nvim_set_hl(0, 'TelescopePreviewLine', {
                            bg = '#3c3836',  -- You can customize this color
                            bold = true
                          })

                          -- Clear any existing highlights in this namespace
                          local ns_id = vim.api.nvim_create_namespace('telescope_preview_highlight')
                          vim.api.nvim_buf_clear_namespace(bufnr2, ns_id, 0, -1)

                          -- Highlight the target row
                          -- vim.api.nvim_buf_add_highlight(bufnr, ns_id, 'TelescopePreviewLine', target_row - 1, 0, -1)
                          local line_content = vim.api.nvim_buf_get_lines(bufnr2, target_row - 1, target_row, false)[1] or ""
                          local line_length = #line_content
                            vim.api.nvim_buf_set_extmark(bufnr2, ns_id, target_row - 1, 0, {
                                end_row = target_row - 1,
                                end_col = line_length,  -- or your desired end column
                                hl_group = 'TelescopePreviewLine',
                                hl_eol = true,  -- if you want to highlight to end of line
                            })
                        else
                          print("WARNING: target row", target_row, "outside buffer range 1-" .. total_lines)
                        end
                      end
                    end)
                  end
                end
              })
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
