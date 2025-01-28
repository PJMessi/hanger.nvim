local Rust = {}

function Rust.get_package_test_command()
    local package_name = Rust.find_package_name()
    if not package_name then
        print("No Cargo.toml found.")
        return
    end

    local test_pattern = Rust.get_test_pattern()
    if not test_pattern then
        print("Cannot find mod name.")
        return
    end

    return string.format(
        "cargo test --package %s -- %s --show-output",
        package_name,
        test_pattern
    )
end

function Rust.get_single_test_command()
    local package_name = Rust.find_package_name()
    if not package_name then
        print("No Cargo.toml found.")
        return
    end

    local test_name = Rust.get_current_test_name()
    if not test_name then
        print("Cursor is not inside a test function.")
        return
    end

    local module_name = Rust.get_test_pattern()
    if not module_name then
        print("Cannot find mod name.")
        return
    end

    local test_pattern = string.format("%s::%s", module_name, test_name)

    return string.format(
        "cargo test --package %s -- %s --exact --show-output",
        package_name,
        test_pattern
    )
end

function Rust.find_package_name()
    local current_dir = vim.fn.expand("%:p:h")

    while current_dir ~= "/" do
        if vim.fn.glob(current_dir .. "/Cargo.toml") ~= "" then
            return vim.fn.fnamemodify(current_dir, ":t")
        end

        current_dir = vim.fn.fnamemodify(current_dir, ":h")
    end

    return nil
end

function Rust.get_current_test_name()
    local current_line = vim.fn.line(".")
    local test_name = nil

    -- Search backwards for the function definition
    for i = current_line, 1, -1 do
        local line = vim.fn.getline(i)

        -- Match Rust test function: `fn test_name()`
        test_name = string.match(line, "^%s*fn%s+([%w_]+)%s*%(")
        if test_name then
            return test_name
        end
    end

    return nil
end

function Rust.get_test_pattern()
    local test_module = nil

    -- Search backwards for test module declarations
    local current_line = vim.fn.line(".")
    for i = current_line, 1, -1 do
        local line = vim.fn.getline(i)
        local module_name = string.match(line, "^%s*mod%s+([%w_]+)%s*{")
        if module_name then
            test_module = module_name
            break
        end
    end

    if test_module == nil then
        return nil
    end

    local file_name_without_ext = vim.fn.expand("%:t:r")
    if file_name_without_ext == "main" or file_name_without_ext == "lib" then
        return test_module
    end

    -- Initialize test pattern with test module.
    local test_pattern = test_module

    -- If the current file is not a mod file, attach the filename with the test module.
    if file_name_without_ext ~= "mod" then
        test_pattern = string.format("%s::%s", file_name_without_ext, test_pattern)
    end

    -- Recursively find parent modules by traversing up the directory structure.
    local current_dir = vim.fn.expand("%:p:h")
    while Rust.has_mod_rs(current_dir) do
        local parent_folder_name = vim.fn.fnamemodify(current_dir, ":t")
        test_pattern = string.format("%s::%s", parent_folder_name, test_pattern)
        current_dir = vim.fn.fnamemodify(current_dir, ":h") -- Move up one directory
    end

    return test_pattern
end

function Rust.has_mod_rs(directory)
    local mod_rs_path = directory .. "/mod.rs"
    return vim.fn.filereadable(mod_rs_path) == 1
end

return Rust
