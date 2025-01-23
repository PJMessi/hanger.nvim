local testActions = require("hanger.test_actions.init")

local M = {}

M.run_single_test = testActions.run_single_test
M.run_tests_in_file = testActions.run_tests_in_file
M.rerun_test = testActions.rerun_test
M.setup = testActions.setup

return M
