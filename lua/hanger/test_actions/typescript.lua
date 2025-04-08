local Typescript = {}
local javascript = require("hanger.test_actions.javascript")

-- For typescript, make sure ts-jest is also installed with proper config.
-- Config example: in package.json (taken from NestJS's package.json)
-- "jest": {
--   "moduleFileExtensions": [
--     "js",
--     "json",
--     "ts"
--   ],
--   "rootDir": "src",
--   "testRegex": ".*\\.spec\\.ts$",
--   "transform": {
--     "^.+\\.(t|j)s$": "ts-jest"
--   },
--   "collectCoverageFrom": [
--     "**/*.(t|j)s"
--   ],
--   "coverageDirectory": "../coverage",
--   "testEnvironment": "node"
-- }

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
