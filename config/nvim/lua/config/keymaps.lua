-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- `;` acts like `:` (enter command-line mode)
vim.keymap.set({ "n", "x" }, ";", ":", { desc = "Command mode" })

-- `<C-n>` toggles the snacks explorer (left file bar) from anywhere.
-- Snacks.explorer() is a genuine toggle: opens if closed, closes if open
-- (even when focused in another window).
vim.keymap.set("n", "<C-n>", function()
  Snacks.explorer()
end, { desc = "Toggle Explorer" })

-- `<leader>e` reveals the current file in the explorer and focuses the tree,
-- opening it if closed. Works even when the tree is already open or focused.
vim.keymap.set("n", "<leader>e", function()
  -- Resolve the file from the current buffer *before* reveal may shift focus.
  local file = vim.api.nvim_buf_get_name(0)
  local explorer = Snacks.explorer.reveal({ file = file ~= "" and file or nil })
  if explorer then
    explorer:focus("list")
  end
end, { desc = "Focus current file in Explorer" })

-- Keep the cursor centered when navigating and searching.
-- `zz` recenters the view after the motion; `zv` opens any fold at the target.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })
vim.keymap.set("n", "*", "*zzzv", { desc = "Search word under cursor (centered)" })
vim.keymap.set("n", "#", "#zzzv", { desc = "Search word under cursor back (centered)" })
vim.keymap.set("n", "G", "Gzz", { desc = "Go to end (centered)" })
vim.keymap.set("n", "gg", "ggzz", { desc = "Go to start (centered)" })
-- Jumplist navigation is a big teleport across the file; recenter after.
vim.keymap.set("n", "<C-o>", "<C-o>zz", { desc = "Jump back (centered)" })
vim.keymap.set("n", "<C-i>", "<C-i>zz", { desc = "Jump forward (centered)" })
