local greet = require("hanger.greet")
local bufAction = require("hanger.path_action")

local M = {}

M.greet = greet.greet_user
M.copy_buf_abs_path = bufAction.copy_buf_abs_path

return M
