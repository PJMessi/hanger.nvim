local Go = {}
local term = require("hanger.test_actions.terminal")


local function get_test_func_name()
    -- Get buffer and parser
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, "go")
    if not parser then return nil, nil end

    -- Get node at cursor
    local tree = parser:parse()[1]
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local node = tree:root():named_descendant_for_range(row, col, row, col)

    -- Find containing function or method
    while node and node:type() ~= "function_declaration" and node:type() ~= "method_declaration" do
        node = node:parent()
    end
    if not node then return nil, nil end

    -- Get function name
    local name_node = node:field("name")[1]
    if not name_node then return nil, nil end
    local func_name = vim.treesitter.get_node_text(name_node, buf)

    -- Check if it's a test function
    if not func_name:match("^Test") then return nil, nil end

    -- If it's a method, find the suite runner
    if node:type() == "method_declaration" then
        -- Simpler approach to get receiver type
        local receiver = node:field("receiver")[1]
        if receiver then
            for i = 0, receiver:named_child_count() - 1 do
                local param = receiver:named_child(i)
                if param and param:type() == "parameter_declaration" then
                    for j = 0, param:named_child_count() - 1 do
                        local child = param:named_child(j)
                        if child and child:type() == "pointer_type" then
                            local type_node = child:named_child(0)
                            if type_node then
                                local receiver_type = vim.treesitter.get_node_text(type_node, buf)

                                if receiver_type:match("Suite$") then
                                    -- Find the suite runner using a simpler query
                                    local runner_query = vim.treesitter.query.parse("go", [[
                                        (function_declaration
                                          name: (identifier) @func_name
                                          body: (block
                                            (expression_statement
                                              (call_expression
                                                function: (selector_expression
                                                  field: (field_identifier) @method (#eq? @method "Run")
                                                )
                                                arguments: (argument_list
                                                  (_)
                                                  (call_expression
                                                    function: (identifier) @new (#eq? @new "new")
                                                    arguments: (argument_list
                                                      (type_identifier) @suite_type
                                                    )
                                                  )
                                                )
                                              )
                                            )
                                          )
                                        )
                                    ]])

                                    -- Iterate through all function declarations
                                    for _, func_node in ipairs(tree:root():named_children()) do
                                        if func_node:type() == "function_declaration" then
                                            for id, matched_node in runner_query:iter_captures(func_node, buf) do
                                                local capture_name = runner_query.captures[id]
                                                if capture_name == "suite_type" then
                                                    local suite_type = vim.treesitter.get_node_text(matched_node, buf)
                                                    if suite_type == receiver_type then
                                                        -- Get the function name
                                                        local fn_node = func_node:field("name")[1]
                                                        local fn_name = vim.treesitter.get_node_text(fn_node, buf)
                                                        return func_name, fn_name
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Regular test or suite runner
    return func_name, nil
end


local function get_package_rel_path()
    local file_path = vim.fn.expand("%")
    return vim.fn.fnamemodify(file_path, ":h")
end

local function build_cmd(rel_path, test_func_name, suite_name)
    if test_func_name == nil then
        return string.format("go test ./%s -count=1 -v", rel_path)
    end

    if suite_name == nil then
        return string.format("go test ./%s -run ^%s$ -count=1 -v", rel_path, test_func_name)
    end

    return string.format("go test ./%s -run ^%s$/%s$ -count=1 -v", rel_path, suite_name, test_func_name)
end

function Go.execute_single(config)
    local test_func_name, suite_name = get_test_func_name()
    if test_func_name == nil then
        vim.notify("could not extract test function name", vim.log.levels.WARN)
        return
    end

    local rel_path = get_package_rel_path()
    local cmd = build_cmd(rel_path, test_func_name, suite_name)
    term.execute(cmd, config)
end

function Go.execute_package(config)
    local rel_path = get_package_rel_path()
    local cmd = build_cmd(rel_path, nil)
    term.execute(cmd, config)
end

return Go
