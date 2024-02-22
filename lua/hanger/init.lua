local greet = require("hanger.greet")
local bufAction = require("hanger.path_action")

local M = {}

M.greet = greet.greet_user
M.copyAbsPath = bufAction.copy_abs_path

return M
