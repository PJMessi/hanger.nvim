# Neovim Test Runner Plugin

A lightweight Neovim plugin designed to run and manage tests for Rust and Go projects. It seamlessly integrates with Neovim's terminal or Zellij, providing a convenient floating pane to execute test commands. With easy-to-use commands, it allows you to run individual tests, rerun tests, and view runnable tests directly from Neovim, improving your development workflow.

## Features

- **RunSingleTest**: Executes a single test function where the cursor is currently located.
- **RunFileTests**: Runs all tests in the current file or package.
- **RerunTest**: Re-executes the last test that was run, regardless of cursor position. Ideal for quickly iterating on tests without needing to manually locate the test function in the file again.
- **ShowRunnables**: Displays a list of executable code segments, such as functions or tests, within the current file or project. This allows you to quickly identify and run specific sections of your code without manually searching for them.

## Requirements
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) – Popup UI for selecting test functions.
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) – Required by Telescope.
- [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) – Used for parsing Go test functions.
- **Rust Analyzer** – Required for running Rust tests (`rust-analyzer` must be installed and configured in Neovim).

## Installation

Use your preferred plugin manager to install the plugin.

### Using Lazy
```lua
{
    "https://github.com/PJMessi/hanger",
    lazy = false,
    cmd = { "RunSingleTest", "RerunSingleTest", "RunFileTests", "ShowRunnables" },
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("hanger").setup({
        output = "term",      -- options: 'term' / 'zellij'
        floating_pane = false, -- only valid for 'zellij' 'output'
      })

      vim.api.nvim_set_keymap('n', '<leader>rt', ':RunSingleTest<CR>',
        { desc = '[R]un [T]est', noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>rrt', ':RerunTest<CR>',
        { desc = '[R]e [R]un [T]est', noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>rft', ':RunFileTests<CR>',
        { desc = '[R]un [F]ile [T]ests', noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>sr', ':ShowRunnables<CR>',
        { desc = '[S]how [R]unnables', noremap = true, silent = true })
    end,
}
```

## Coming Soon
Support for additional programming languages will be added in future releases. Stay tuned for more!

