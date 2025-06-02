local testActions = require("hanger.test_actions.init")

local M = {}

M.run_test = testActions.run_test
M.run_all_tests = testActions.run_all_tests
M.rerun_test = testActions.rerun_test
M.show_tests = testActions.show_tests
M.setup = testActions.setup

return M
