local Typescript = {}
local javascript = require("hanger.test_actions.javascript")

function Typescript.execute_single(config)
    javascript.execute_single(config, true)
end

function Typescript.execute_package(config)
    javascript.execute_package(config)
end

function Typescript.show_runnables(config)
    javascript.show_runnables(config, true)
end

return Typescript
