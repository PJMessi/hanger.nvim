local greet = require("hanger.greet")
local bufAction = require("hanger.path_action")
local testActions = require("hanger.test_actions")
local makefileActions = require("hanger.make_file_actions")

local M = {}

M.greet = greet.greet_user
M.copy_buf_abs_path = bufAction.copy_buf_abs_path
M.run_single_test = testActions.run_single_test
M.run_tests_in_file = testActions.run_tests_in_file
M.rerun_single_test = testActions.rerun_single_test
M.dispay_make_commands = makefileActions.dispay_make_commands

return M
